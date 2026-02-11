package com.vib3.flutter

import android.graphics.SurfaceTexture
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLSurface
import android.opengl.GLES20
import android.os.Handler
import android.os.HandlerThread
import android.view.Surface
import android.view.Choreographer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.nio.ShortBuffer

class Vib3FlutterPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var textureRegistry: TextureRegistry
    private var engineState: Vib3EngineState? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.vib3.engine")
        channel.setMethodCallHandler(this)
        textureRegistry = flutterPluginBinding.textureRegistry
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val args = call.arguments as Map<*, *>
                val entry = textureRegistry.createSurfaceTexture()
                val textureId = entry.id()
                engineState = Vib3EngineState(entry)
                engineState?.initialize()
                result.success(mapOf("textureId" to textureId))
            }
            "dispose" -> {
                engineState?.dispose()
                engineState = null
                result.success(null)
            }
            "setSystem" -> {
                val system = call.argument<String>("system") ?: "quantum"
                engineState?.setSystem(system)
                result.success(null)
            }
            "setGeometry" -> {
                val index = call.argument<Int>("index") ?: 0
                engineState?.setGeometry(index)
                result.success(null)
            }
            "setVisualParams" -> {
                val params = call.arguments as Map<String, Double>
                params.forEach { (k, v) -> engineState?.setVisualParam(k, v.toFloat()) }
                result.success(null)
            }
            "rotate" -> {
                val plane = call.argument<String>("plane") ?: "xy"
                val angle = call.argument<Double>("angle")?.toFloat() ?: 0f
                engineState?.rotate(plane, angle)
                result.success(null)
            }
            "setRotation" -> {
                val args = call.arguments as Map<String, Double>
                engineState?.setRotation(
                    args["xy"]?.toFloat() ?: 0f,
                    args["xz"]?.toFloat() ?: 0f,
                    args["yz"]?.toFloat() ?: 0f,
                    args["xw"]?.toFloat() ?: 0f,
                    args["yw"]?.toFloat() ?: 0f,
                    args["zw"]?.toFloat() ?: 0f
                )
                result.success(null)
            }
            "resetRotation" -> {
                engineState?.resetRotation()
                result.success(null)
            }
            "startRendering" -> {
                engineState?.startRendering()
                result.success(null)
            }
            "stopRendering" -> {
                engineState?.stopRendering()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        engineState?.dispose()
    }
}

class Vib3EngineState(private val textureEntry: TextureRegistry.SurfaceTextureEntry) {
    private var glThread: HandlerThread? = null
    private var glHandler: Handler? = null
    private var eglDisplay: EGLDisplay? = null
    private var eglContext: EGLContext? = null
    private var eglSurface: EGLSurface? = null
    private var program = 0

    private val lock = Object()
    private var isRendering = false
    private val textureSize = 512 // Fixed resolution for performance

    // Parameters
    private var currentSystem = "quantum"
    private var currentGeometry = 0f
    private val rotation = FloatArray(6)
    private val visualParams = mutableMapOf<String, Float>()

    // Geometry buffers (Fullscreen Quad)
    private var vertexBuffer: FloatBuffer? = null
    private var indexBuffer: ShortBuffer? = null

    // Shaders Sources
    private val UNIFORMS = """
        #ifdef GL_FRAGMENT_PRECISION_HIGH
            precision highp float;
        #else
            precision mediump float;
        #endif

        uniform float u_time;
        uniform vec2 u_resolution;
        uniform float u_geometry;

        uniform float u_rot4dXY;
        uniform float u_rot4dXZ;
        uniform float u_rot4dYZ;
        uniform float u_rot4dXW;
        uniform float u_rot4dYW;
        uniform float u_rot4dZW;

        uniform float u_dimension;
        uniform float u_gridDensity;
        uniform float u_morphFactor;
        uniform float u_chaos;
        uniform float u_speed;
        uniform float u_hue;
        uniform float u_intensity;
        uniform float u_saturation;

        uniform float u_mouseIntensity;
        uniform float u_clickIntensity;
        uniform vec2 u_mouse;

        // Layer params
        uniform float u_roleIntensity;
    """.trimIndent()

    private val ROTATION_LIB = """
        mat4 rotateXY(float angle) {
            float c = cos(angle); float s = sin(angle);
            return mat4(c, -s, 0, 0, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
        }
        mat4 rotateXZ(float angle) {
            float c = cos(angle); float s = sin(angle);
            return mat4(c, 0, -s, 0, 0, 1, 0, 0, s, 0, c, 0, 0, 0, 0, 1);
        }
        mat4 rotateYZ(float angle) {
            float c = cos(angle); float s = sin(angle);
            return mat4(1, 0, 0, 0, 0, c, -s, 0, 0, s, c, 0, 0, 0, 0, 1);
        }
        mat4 rotateXW(float angle) {
            float c = cos(angle); float s = sin(angle);
            return mat4(c, 0, 0, -s, 0, 1, 0, 0, 0, 0, 1, 0, s, 0, 0, c);
        }
        mat4 rotateYW(float angle) {
            float c = cos(angle); float s = sin(angle);
            return mat4(1, 0, 0, 0, 0, c, 0, -s, 0, 0, 1, 0, 0, s, 0, c);
        }
        mat4 rotateZW(float angle) {
            float c = cos(angle); float s = sin(angle);
            return mat4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, c, -s, 0, 0, s, c);
        }
    """.trimIndent()

    // GEOMETRY24 (Condensed for brevity but functional)
    private val GEOMETRY_LIB = """
        float baseGeometry(vec4 p, float type) {
            if (type < 0.5) { // Tetrahedron
                return max(max(max(abs(p.x + p.y) - p.z, abs(p.x - p.y) - p.z), abs(p.x + p.y) + p.z), abs(p.x - p.y) + p.z) / sqrt(3.0);
            } else if (type < 1.5) { // Hypercube
                vec4 q = abs(p) - 0.8;
                return length(max(q, 0.0)) + min(max(max(max(q.x, q.y), q.z), q.w), 0.0);
            } else if (type < 2.5) { // Sphere
                return length(p) - 1.0;
            } else if (type < 3.5) { // Torus
                vec2 t = vec2(length(p.xy) - 0.8, p.z);
                return length(t) - 0.3;
            } else if (type < 4.5) { // Klein
                float r = length(p.xy);
                return abs(r - 0.7) - 0.2 + sin(atan(p.y, p.x) * 3.0 + p.z * 5.0) * 0.1;
            } else if (type < 5.5) { // Fractal
                return length(p) - 0.8 + sin(p.x * 5.0) * sin(p.y * 5.0) * sin(p.z * 5.0) * 0.2;
            } else if (type < 6.5) { // Wave
                return abs(p.z - sin(p.x * 5.0 + u_time) * cos(p.y * 5.0 + u_time) * 0.3) - 0.1;
            } else { // Crystal
                vec4 q = abs(p);
                return max(max(max(q.x, q.y), q.z), q.w) - 0.8;
            }
        }
        float hypersphereCore(vec4 p, float baseType) {
            float baseShape = baseGeometry(p, baseType);
            float sphereField = length(p) - 1.2;
            return max(baseShape, sphereField);
        }
        float hypertetrahedronCore(vec4 p, float baseType) {
            float baseShape = baseGeometry(p, baseType);
            float tetraField = max(max(max(abs(p.x+p.y)-p.z-p.w, abs(p.x-p.y)-p.z+p.w), abs(p.x+p.y)+p.z-p.w), abs(p.x-p.y)+p.z+p.w) / sqrt(4.0);
            return max(baseShape, tetraField);
        }
        float geometry(vec4 p, float type) {
            if (type < 8.0) return baseGeometry(p, type);
            else if (type < 16.0) return hypersphereCore(p, type - 8.0);
            else return hypertetrahedronCore(p, type - 16.0);
        }
        float geometryFunction(vec4 p) { return geometry(p, u_geometry); }
    """.trimIndent()

    // HOLOGRAPHIC SHADER (The one found in investigation)
    private val HOLOGRAPHIC_FRAG = """
        vec3 getLayerColorPalette(int layerIndex, float t) {
            if (layerIndex == 0) { return mix(mix(vec3(0.05, 0.0, 0.2), vec3(0.0, 0.0, 0.1), sin(t * 3.0) * 0.5 + 0.5), vec3(0.0, 0.05, 0.3), cos(t * 2.0) * 0.5 + 0.5); }
            else if (layerIndex == 1) { return mix(mix(vec3(0.0, 1.0, 0.0), vec3(0.8, 1.0, 0.0), sin(t * 7.0) * 0.5 + 0.5), vec3(0.0, 0.8, 0.3), cos(t * 5.0) * 0.5 + 0.5); }
            else if (layerIndex == 2) { return mix(mix(vec3(1.0, 0.0, 0.0), vec3(1.0, 0.5, 0.0), sin(t * 11.0) * 0.5 + 0.5), vec3(1.0, 1.0, 1.0), cos(t * 8.0) * 0.5 + 0.5); }
            else if (layerIndex == 3) { return mix(mix(vec3(0.0, 1.0, 1.0), vec3(0.0, 0.5, 1.0), sin(t * 13.0) * 0.5 + 0.5), vec3(0.5, 1.0, 1.0), cos(t * 9.0) * 0.5 + 0.5); }
            else { return mix(mix(vec3(1.0, 0.0, 1.0), vec3(0.8, 0.0, 1.0), sin(t * 17.0) * 0.5 + 0.5), vec3(1.0, 0.3, 1.0), cos(t * 12.0) * 0.5 + 0.5); }
        }
        vec3 extremeRGBSeparation(vec3 baseColor, vec2 uv, float intensity, int layerIndex) {
            if (layerIndex == 0) return baseColor + vec3(sin(uv.x * 10.0) * 0.02);
            else return baseColor + vec3(0.01 * intensity);
        }
        void main() {
            vec2 uv = (gl_FragCoord.xy - u_resolution.xy * 0.5) / min(u_resolution.x, u_resolution.y);
            float timeSpeed = u_time * 0.0001 * u_speed;
            vec4 pos = vec4(uv * 3.0, sin(timeSpeed * 3.0), cos(timeSpeed * 2.0));
            pos = rotateXY(u_rot4dXY) * pos; pos = rotateXZ(u_rot4dXZ) * pos; pos = rotateYZ(u_rot4dYZ) * pos;
            pos = rotateXW(u_rot4dXW) * pos; pos = rotateYW(u_rot4dYW) * pos; pos = rotateZW(u_rot4dZW) * pos;
            float value = geometryFunction(pos);
            float geometryIntensity = 1.0 - clamp(abs(value * 0.8), 0.0, 1.0);
            geometryIntensity = pow(geometryIntensity, 1.5) * u_intensity;
            int layerIndex = 0;
            if (u_roleIntensity == 0.7) layerIndex = 1; else if (u_roleIntensity == 1.0) layerIndex = 2;
            else if (u_roleIntensity == 0.85) layerIndex = 3; else if (u_roleIntensity == 0.6) layerIndex = 4;
            vec3 finalColor = getLayerColorPalette(layerIndex, timeSpeed) * geometryIntensity;
            gl_FragColor = vec4(finalColor, geometryIntensity);
        }
    """.trimIndent()

    private val QUANTUM_FRAG = """
        void main() {
            vec2 uv = (gl_FragCoord.xy - u_resolution.xy * 0.5) / min(u_resolution.x, u_resolution.y);
            float timeSpeed = u_time * 0.0001 * u_speed;
            vec4 pos = vec4(uv * 3.0, sin(timeSpeed * 3.0), cos(timeSpeed * 2.0));
            pos = rotateXY(u_rot4dXY) * pos; pos = rotateXZ(u_rot4dXZ) * pos; pos = rotateYZ(u_rot4dYZ) * pos;
            pos = rotateXW(u_rot4dXW) * pos; pos = rotateYW(u_rot4dYW) * pos; pos = rotateZW(u_rot4dZW) * pos;
            float value = geometryFunction(pos);
            float geometryIntensity = 1.0 - clamp(abs(value * 0.8), 0.0, 1.0);
            vec3 color = vec3(0.0, 0.8, 1.0) * geometryIntensity * u_intensity; // Simple Blue Quantum for now
            gl_FragColor = vec4(color, geometryIntensity);
        }
    """.trimIndent()

    init {
        glThread = HandlerThread("Vib3GL")
        glThread?.start()
        glHandler = Handler(glThread!!.looper)
    }

    fun initialize() {
        glHandler?.post {
            initGL()
            generateQuad()
        }
    }

    private fun initGL() {
        eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        val version = IntArray(2)
        EGL14.eglInitialize(eglDisplay, version, 0, version, 1)
        val configAttribs = intArrayOf(EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT, EGL14.EGL_RED_SIZE, 8, EGL14.EGL_GREEN_SIZE, 8, EGL14.EGL_BLUE_SIZE, 8, EGL14.EGL_ALPHA_SIZE, 8, EGL14.EGL_NONE)
        val configs = arrayOfNulls<EGLConfig>(1)
        val numConfigs = IntArray(1)
        EGL14.eglChooseConfig(eglDisplay, configAttribs, 0, configs, 0, 1, numConfigs, 0)
        val contextAttribs = intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE)
        eglContext = EGL14.eglCreateContext(eglDisplay, configs[0], EGL14.EGL_NO_CONTEXT, contextAttribs, 0)
        val surfaceTexture = textureEntry.surfaceTexture()
        surfaceTexture.setDefaultBufferSize(textureSize, textureSize)
        eglSurface = EGL14.eglCreateWindowSurface(eglDisplay, configs[0], surfaceTexture, intArrayOf(EGL14.EGL_NONE), 0)
        EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)
        loadProgram(currentSystem)
    }

    private fun loadProgram(system: String) {
        val vert = """
            attribute vec4 aPosition;
            void main() { gl_Position = aPosition; }
        """.trimIndent()

        val fragMain = if (system == "holographic") HOLOGRAPHIC_FRAG else QUANTUM_FRAG
        val frag = UNIFORMS + ROTATION_LIB + GEOMETRY_LIB + fragMain

        if (program != 0) GLES20.glDeleteProgram(program)
        val vs = loadShader(GLES20.GL_VERTEX_SHADER, vert)
        val fs = loadShader(GLES20.GL_FRAGMENT_SHADER, frag)
        program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vs)
        GLES20.glAttachShader(program, fs)
        GLES20.glLinkProgram(program)
        GLES20.glDeleteShader(vs)
        GLES20.glDeleteShader(fs)
    }

    private fun loadShader(type: Int, src: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, src)
        GLES20.glCompileShader(shader)
        return shader
    }

    private fun generateQuad() {
        val verts = floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f)
        val bb = ByteBuffer.allocateDirect(verts.size * 4).order(ByteOrder.nativeOrder())
        vertexBuffer = bb.asFloatBuffer().put(verts)
        vertexBuffer?.position(0)
    }

    fun setSystem(sys: String) {
        currentSystem = sys
        glHandler?.post { loadProgram(sys) }
    }
    fun setGeometry(idx: Int) { currentGeometry = idx.toFloat() }
    fun setVisualParam(k: String, v: Float) { visualParams[k] = v }
    fun setRotation(xy: Float, xz: Float, yz: Float, xw: Float, yw: Float, zw: Float) {
        synchronized(lock) {
            rotation[0] = xy; rotation[1] = xz; rotation[2] = yz
            rotation[3] = xw; rotation[4] = yw; rotation[5] = zw
        }
    }
    fun rotate(p: String, a: Float) {} // Simplified
    fun resetRotation() {}

    fun startRendering() {
        if (isRendering) return
        isRendering = true
        Choreographer.getInstance().postFrameCallback(frameCallback)
    }
    fun stopRendering() { isRendering = false }

    private val frameCallback = object : Choreographer.FrameCallback {
        override fun doFrame(frameTimeNanos: Long) {
            if (!isRendering) return
            glHandler?.post { render(frameTimeNanos) }
            Choreographer.getInstance().postFrameCallback(this)
        }
    }

    private fun render(time: Long) {
        if (eglDisplay == null) return
        GLES20.glViewport(0, 0, textureSize, textureSize)
        GLES20.glClearColor(0f, 0f, 0f, 0f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        GLES20.glUseProgram(program)

        val posLoc = GLES20.glGetAttribLocation(program, "aPosition")
        GLES20.glEnableVertexAttribArray(posLoc)
        GLES20.glVertexAttribPointer(posLoc, 2, GLES20.GL_FLOAT, false, 0, vertexBuffer)

        // Uniforms
        GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "u_time"), (time / 1_000_000).toFloat())
        GLES20.glUniform2f(GLES20.glGetUniformLocation(program, "u_resolution"), textureSize.toFloat(), textureSize.toFloat())
        GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "u_geometry"), currentGeometry)

        GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "u_rot4dXY"), rotation[0])
        GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "u_rot4dXZ"), rotation[1])
        GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "u_rot4dYZ"), rotation[2])
        GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "u_rot4dXW"), rotation[3])
        GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "u_rot4dYW"), rotation[4])
        GLES20.glUniform1f(GLES20.glGetUniformLocation(program, "u_rot4dZW"), rotation[5])

        // Visual Params
        val keys = arrayOf("chaos", "speed", "hue", "intensity", "saturation", "roleIntensity")
        for (k in keys) {
            val v = visualParams[k] ?: if (k == "speed") 1f else 0f
            val name = if (k == "roleIntensity") "u_roleIntensity" else "u_$k"
            GLES20.glUniform1f(GLES20.glGetUniformLocation(program, name), v)
        }

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        EGL14.eglSwapBuffers(eglDisplay, eglSurface)
    }

    fun dispose() {
        stopRendering()
        glHandler?.post {
            glThread?.quit()
        }
    }
}

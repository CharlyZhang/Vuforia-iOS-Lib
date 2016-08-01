#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
out vec4     fragColor;
#else
varying vec2 varTexcoord;
#endif

uniform vec4 inColor;

void main (void)
{
    gl_FragColor = inColor;
}

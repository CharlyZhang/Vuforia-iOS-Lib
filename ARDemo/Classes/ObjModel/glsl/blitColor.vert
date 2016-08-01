#ifdef GL_ES
precision highp float;
#endif

uniform mat4 mvpMat;

#if __VERSION__ >= 140
in vec4  inPosition;
#else
attribute vec4 inPosition;
#endif

void main (void)
{
    gl_Position	= mvpMat * inPosition;
}

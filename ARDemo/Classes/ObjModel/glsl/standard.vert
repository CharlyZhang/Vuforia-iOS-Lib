//#version 150

#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
in vec3 vert;
in vec3 vertNormal;
in vec2 vertTexCoord;
out vec3 fragVert;
out vec2 fragTexCoord;
out vec3 fragNormal;
#else
attribute vec3 vert;
attribute vec3 vertNormal;
attribute vec2 vertTexCoord;
varying vec3 fragVert;
varying vec2 fragTexCoord;
varying vec3 fragNormal;
#endif

uniform mat4 mvpMat;
uniform mat4 modelMat;

void main() {
    // Pass some variables to the fragment shader
    fragTexCoord = vertTexCoord;
    
    fragNormal = vertNormal;
    fragVert = (modelMat * vec4(vert,1)).xyz;

	gl_Position = mvpMat * vec4(vert, 1);
}
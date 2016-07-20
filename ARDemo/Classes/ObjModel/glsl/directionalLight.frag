//#version 150

#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
in vec2      fragTexCoord;
in vec3      fragNormal;
in vec3      fragVert;

#define TEXTURE		texture

#else
varying vec2      fragTexCoord;
varying vec3      fragNormal;
varying vec3      fragVert;

#define TEXTURE		texture2D
#endif

uniform sampler2D tex;
uniform int hasTex;

uniform struct AmbientLight
{
	vec3 intensities;
} ambientLight;

uniform struct DirectionalLight
{
	vec3 direction;
	vec3 intensities;
} directionalLight;

uniform struct Material
{
    float Ns;
    vec3 ke;
    vec3 ka;
    vec3 kd;
    vec3 ks;
} material;

uniform vec3 eyePosition;
uniform mat4 modelInverseTransposeMat;

//// ignore the kd and ka of material and lock them together

void main()
{
    
    float texU = fragTexCoord.x -floor(fragTexCoord.x);
    float texV = fragTexCoord.y - floor(fragTexCoord.y);
    
    vec4 surfaceColor = TEXTURE(tex, vec2(texU,texV));
    if(hasTex == 0) surfaceColor = vec4(1.0,1.0,1.0,1.0) ;
    
    // emissive
    vec3 emissive = material.ke;
    // ambient
//    vec3 ambient = material.ka * ambientLight.intensities;
    vec3 ambient = ambientLight.intensities;
    
    // diffuse
    vec4 normal = modelInverseTransposeMat * vec4(fragNormal,1.0);
    vec3 N = normalize(normal.xyz);
    vec3 L = normalize(-directionalLight.direction);     // lightPosition - fragVert
    float brightness = max(dot(N,L), 0.0);
    vec3 diffuse = directionalLight.intensities * brightness;
    if (hasTex == 0) diffuse = material.kd * directionalLight.intensities * brightness;
    
    // specular
    vec3 V = normalize(eyePosition - fragVert);
    vec3 H = normalize(L + V);
    float specularLight = pow(max(dot(N,H), 0.0), material.Ns);
    specularLight = max(specularLight, 0.0);
    vec3 specular = material.ks * directionalLight.intensities * specularLight;
//    vec3 specular = directionalLight.intensities * specularLight;
    
    gl_FragColor.rgb = emissive + ambient + diffuse + specular;
    gl_FragColor.rgb = gl_FragColor.rgb * surfaceColor.rgb;
    gl_FragColor.a = 1.0;
    
    
    //// debug
    
//    gl_FragColor.rgb = fragNormal;
//	gl_FragColor.rgb = surfaceColor.rgb;
//	gl_FragColor.rgb = vec3(fragTexCoord,0.0);
}

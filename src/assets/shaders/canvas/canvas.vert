#version 450 core

// Copyright (C) 2017, Benjamin 'BeRo' Rosseaux (benjamin@rosseaux.de)
// License: zlib 

layout(location = 0) in vec2 inPosition; 
layout(location = 1) in vec4 inColor;    
layout(location = 2) in vec3 inTexCoord; 
layout(location = 3) in uint inState;    
layout(location = 4) in vec4 inClipRect; 
layout(location = 5) in vec4 inMetaInfo; 

layout(location = 0) out vec2 outPosition;
layout(location = 1) out vec4 outColor;
layout(location = 2) out vec3 outTexCoord;
layout(location = 3) flat out ivec4 outState;    
layout(location = 4) out vec4 outClipRect; 
layout(location = 5) out vec4 outMetaInfo; 

layout(push_constant) uniform PushConstants {
  layout(offset = 0) mat4 transformMatrix;
  layout(offset = 64) mat4 fillMatrix;
} pushConstants;

out gl_PerVertex {
  vec4 gl_Position;   
};

void main(void){
  outPosition = inPosition;
  outColor = inColor;
  outTexCoord = inTexCoord;
  outState = ivec4(uvec4((inState >> 0u) & 0x3u,
                         (inState >> 2u) & 0xffu,                         
                         (inState >> 10u) & 0xfu,                         
                         0u));
  outClipRect = inClipRect;
  outMetaInfo = inMetaInfo;
  gl_Position = pushConstants.transformMatrix * vec4(inPosition, 0.0, 1.0);
}
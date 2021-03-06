//MIT License
//Copyright (c) 2019 Gonzalo G Campos

/* PRAGMA */
#pragma once


// Source code for geometry shader
static const GLchar* default_geometry[] =
{
"#version 450 core                                                      \n"
"layout (points) in;                                                    \n"
"layout (triangle_strip) out;                                           \n"
"layout (max_vertices = 4) out;                                         \n"
"uniform float minSize;                                                 \n"
"uniform float incSize;                                                 \n"
"in Vertex                                                              \n"
"{                                                                      \n"
"    float VertexLifeTime;                                              \n"
"    float VertexLifeRemaining;                                         \n"
"}vertex[];                                                             \n"
"out vec2 Vertex_UV;                                                    \n"
"out float VertexLifeTime;                                              \n"
"out float VertexLifeRemaining;                                         \n"
"void main()                                                            \n"
"{                                                                      \n"
"   float calcSize = minSize + vertex[0].VertexLifeTime * incSize;      \n"
"   vec4 P = gl_in[0].gl_Position;                                      \n"
"   if(vertex[0].VertexLifeRemaining>0)                                 \n"
"   {                                                                   \n"
"       vec2 va = P.xy + vec2(-0.5, -0.5) * calcSize;                   \n"
"       gl_Position = vec4(va, P.zw);                                   \n"
"       Vertex_UV = vec2(0.0, 1.0);                                     \n"
"       VertexLifeTime = vertex[0].VertexLifeTime;                      \n"
"       VertexLifeRemaining = vertex[0].VertexLifeRemaining;            \n"
"       EmitVertex();                                                   \n"
"       va = P.xy + vec2(-0.5, 0.5) * calcSize;                         \n"
"       gl_Position = vec4(va, P.zw);                                   \n"
"       Vertex_UV = vec2(0.0, 0.0);                                     \n"
"       VertexLifeTime = vertex[0].VertexLifeTime;                      \n"
"       VertexLifeRemaining = vertex[0].VertexLifeRemaining;            \n"
"       EmitVertex();                                                   \n"
"       va = P.xy + vec2(0.5, -0.5) * calcSize;                         \n"
"       gl_Position = vec4(va, P.zw);                                   \n"
"       Vertex_UV = vec2(1.0, 1.0);                                     \n"
"       VertexLifeTime = vertex[0].VertexLifeTime;                      \n"
"       VertexLifeRemaining = vertex[0].VertexLifeRemaining;            \n"
"       EmitVertex();                                                   \n"
"       va = P.xy + vec2(0.5, 0.5) * calcSize;                          \n"
"       gl_Position = vec4(va, P.zw);                                   \n"
"       Vertex_UV = vec2(1.0, 0.0);                                     \n"
"       VertexLifeTime = vertex[0].VertexLifeTime;                      \n"
"       VertexLifeRemaining = vertex[0].VertexLifeRemaining;            \n"
"       EmitVertex();                                                   \n"
"   }                                                                   \n"
"   EndPrimitive();                                                     \n"
"}"
};
//
//     Copyright (C) Pixar. All rights reserved.
//
//     This license governs use of the accompanying software. If you
//     use the software, you accept this license. If you do not accept
//     the license, do not use the software.
//
//     1. Definitions
//     The terms "reproduce," "reproduction," "derivative works," and
//     "distribution" have the same meaning here as under U.S.
//     copyright law.  A "contribution" is the original software, or
//     any additions or changes to the software.
//     A "contributor" is any person or entity that distributes its
//     contribution under this license.
//     "Licensed patents" are a contributor's patent claims that read
//     directly on its contribution.
//
//     2. Grant of Rights
//     (A) Copyright Grant- Subject to the terms of this license,
//     including the license conditions and limitations in section 3,
//     each contributor grants you a non-exclusive, worldwide,
//     royalty-free copyright license to reproduce its contribution,
//     prepare derivative works of its contribution, and distribute
//     its contribution or any derivative works that you create.
//     (B) Patent Grant- Subject to the terms of this license,
//     including the license conditions and limitations in section 3,
//     each contributor grants you a non-exclusive, worldwide,
//     royalty-free license under its licensed patents to make, have
//     made, use, sell, offer for sale, import, and/or otherwise
//     dispose of its contribution in the software or derivative works
//     of the contribution in the software.
//
//     3. Conditions and Limitations
//     (A) No Trademark License- This license does not grant you
//     rights to use any contributor's name, logo, or trademarks.
//     (B) If you bring a patent claim against any contributor over
//     patents that you claim are infringed by the software, your
//     patent license from such contributor to the software ends
//     automatically.
//     (C) If you distribute any portion of the software, you must
//     retain all copyright, patent, trademark, and attribution
//     notices that are present in the software.
//     (D) If you distribute any portion of the software in source
//     code form, you may do so only under this license by including a
//     complete copy of this license with your distribution. If you
//     distribute any portion of the software in compiled or object
//     code form, you may only do so under a license that complies
//     with this license.
//     (E) The software is licensed "as-is." You bear the risk of
//     using it. The contributors give no express warranties,
//     guarantees or conditions. You may have additional consumer
//     rights under your local laws which this license cannot change.
//     To the extent permitted under your local laws, the contributors
//     exclude the implied warranties of merchantability, fitness for
//     a particular purpose and non-infringement.
//

//----------------------------------------------------------
// Patches.TessVertexBSpline
//----------------------------------------------------------
#ifdef OSD_PATCH_VERTEX_BSPLINE_SHADER

layout(location = 0) in vec4 position;
OSD_USER_VARYING_ATTRIBUTE_DECLARE

out block {
    ControlVertex v;
    OSD_USER_VARYING_DECLARE
} outpt;

void main()
{
    outpt.v.position = ModelViewMatrix * position;
    OSD_PATCH_CULL_COMPUTE_CLIPFLAGS(position);
    OSD_USER_VARYING_PER_VERTEX();
}

#endif

//----------------------------------------------------------
// Patches.TessControlBSpline
//----------------------------------------------------------
#ifdef OSD_PATCH_TESS_CONTROL_BSPLINE_SHADER

// Regular
uniform mat4 Q = mat4(
    1.f/6.f, 4.f/6.f, 1.f/6.f, 0.f,
    0.f,     4.f/6.f, 2.f/6.f, 0.f,
    0.f,     2.f/6.f, 4.f/6.f, 0.f,
    0.f,     1.f/6.f, 4.f/6.f, 1.f/6.f
);

// Boundary / Corner
uniform mat4x3 B = mat4x3( 
    1.f,     0.f,     0.f,
    4.f/6.f, 2.f/6.f, 0.f,
    2.f/6.f, 4.f/6.f, 0.f,
    1.f/6.f, 4.f/6.f, 1.f/6.f
);

layout(vertices = 16) out;

in block {
    ControlVertex v;
    OSD_USER_VARYING_DECLARE
} inpt[];

out block {
    ControlVertex v;
    OSD_USER_VARYING_DECLARE
} outpt[];

#define ID gl_InvocationID

void main()
{
    int i = ID%4;
    int j = ID/4;

#if defined OSD_PATCH_BOUNDARY
    vec3 H[3];
    for (int l=0; l<3; ++l) {
        H[l] = vec3(0,0,0);
        for (int k=0; k<4; ++k) {
            H[l] += Q[i][k] * inpt[l*4 + k].v.position.xyz;
        }
    }

    vec3 pos = vec3(0,0,0);
    for (int k=0; k<3; ++k) {
        pos += B[j][k]*H[k];
    }

#elif defined OSD_PATCH_CORNER
    vec3 H[3];
    for (int l=0; l<3; ++l) {
        H[l] = vec3(0,0,0);
        for (int k=0; k<3; ++k) {
            H[l] += B[3-i][2-k] * inpt[l*3 + k].v.position.xyz;
        }
    }

    vec3 pos = vec3(0,0,0);
    for (int k=0; k<3; ++k) {
        pos += B[j][k]*H[k];
    }

#else // not OSD_PATCH_BOUNDARY, not OSD_PATCH_CORNER
    vec3 H[4];
    for (int l=0; l<4; ++l) {
        H[l] = vec3(0,0,0);
        for (int k=0; k<4; ++k) {
            H[l] += Q[i][k] * inpt[l*4 + k].v.position.xyz;
        }
    }

    vec3 pos = vec3(0,0,0);
    for (int k=0; k<4; ++k) {
        pos += Q[j][k]*H[k];
    }

#endif

    outpt[ID].v.position = vec4(pos, 1.0);

#if defined OSD_PATCH_BOUNDARY
    const int p[16] = int[]( 0, 1, 2, 3, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 );
#elif defined OSD_PATCH_CORNER
    const int p[16] = int[]( 0, 1, 2, 2, 0, 1, 2, 2, 3, 4, 5, 5, 6, 7, 8, 8 );
#else
    const int p[16] = int[]( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 );
#endif

#if OSD_TRANSITION_ROTATE == 0
    const int r[16] = int[]( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 );
#elif OSD_TRANSITION_ROTATE == 1
    const int r[16] = int[]( 12, 8, 4, 0, 13, 9, 5, 1, 14, 10, 6, 2, 15, 11, 7, 3 );
#elif OSD_TRANSITION_ROTATE == 2
    const int r[16] = int[]( 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 );
#elif OSD_TRANSITION_ROTATE == 3
    const int r[16] = int[]( 3, 7, 11, 15, 2, 6, 10, 14, 1, 5, 9, 13, 0, 4, 8, 12 );
#endif

    OSD_USER_VARYING_PER_CONTROL_POINT(ID, p[r[ID]]);

    int patchLevel = GetPatchLevel();

    // +0.5 to avoid interpolation error of integer value
    outpt[ID].v.patchCoord = vec4(0, 0,
                                  patchLevel+0.5,
                                  gl_PrimitiveID+LevelBase+0.5);

    OSD_COMPUTE_PTEX_COORD_TESSCONTROL_SHADER;

    if (ID == 0) {
        OSD_PATCH_CULL(OSD_PATCH_INPUT_SIZE);

#ifdef OSD_PATCH_TRANSITION
        vec3 cp[OSD_PATCH_INPUT_SIZE];
        for(int k = 0; k < OSD_PATCH_INPUT_SIZE; ++k) cp[k] = inpt[k].v.position.xyz;
        SetTransitionTessLevels(cp, patchLevel);
#else
    #if defined OSD_PATCH_BOUNDARY
        const int p[4] = int[]( 1, 2, 5, 6 );
    #elif defined OSD_PATCH_CORNER
        const int p[4] = int[]( 1, 2, 4, 5 );
    #else
        const int p[4] = int[]( 5, 6, 9, 10 );
    #endif

    #ifdef OSD_ENABLE_SCREENSPACE_TESSELLATION
        gl_TessLevelOuter[0] = TessAdaptive(inpt[p[0]].v.position.xyz, inpt[p[2]].v.position.xyz);
        gl_TessLevelOuter[1] = TessAdaptive(inpt[p[0]].v.position.xyz, inpt[p[1]].v.position.xyz);
        gl_TessLevelOuter[2] = TessAdaptive(inpt[p[1]].v.position.xyz, inpt[p[3]].v.position.xyz);
        gl_TessLevelOuter[3] = TessAdaptive(inpt[p[2]].v.position.xyz, inpt[p[3]].v.position.xyz);
        gl_TessLevelInner[0] = max(gl_TessLevelOuter[1], gl_TessLevelOuter[3]);
        gl_TessLevelInner[1] = max(gl_TessLevelOuter[0], gl_TessLevelOuter[2]);
    #else
        gl_TessLevelInner[0] = GetTessLevel(patchLevel);
        gl_TessLevelInner[1] = GetTessLevel(patchLevel);
        gl_TessLevelOuter[0] = GetTessLevel(patchLevel);
        gl_TessLevelOuter[1] = GetTessLevel(patchLevel);
        gl_TessLevelOuter[2] = GetTessLevel(patchLevel);
        gl_TessLevelOuter[3] = GetTessLevel(patchLevel);
    #endif
#endif
    }
}

#endif

//----------------------------------------------------------
// Patches.TessEvalBSpline
//----------------------------------------------------------
#ifdef OSD_PATCH_TESS_EVAL_BSPLINE_SHADER

#ifdef OSD_TRANSITION_TRIANGLE_SUBPATCH
    layout(triangles) in;
#else
    layout(quads) in;
#endif

#if defined OSD_FRACTIONAL_ODD_SPACING
    layout(fractional_odd_spacing) in;
#elif defined OSD_FRACTIONAL_EVEN_SPACING
    layout(fractional_even_spacing) in;
#endif

in block {
    ControlVertex v;
    OSD_USER_VARYING_DECLARE
} inpt[];

out block {
    OutputVertex v;
    OSD_USER_VARYING_DECLARE
} outpt;

void main()
{
#ifdef OSD_PATCH_TRANSITION
    vec2 UV = GetTransitionSubpatchUV();
#else
    vec2 UV = gl_TessCoord.xy;
#endif

    float B[4], D[4];

    Univar4x4(UV.x, B, D);

    vec3 BUCP[4], DUCP[4];

    for (int i=0; i<4; ++i) {
        BUCP[i] = vec3(0);
        DUCP[i] = vec3(0);

        for (int j=0; j<4; ++j) {
#if OSD_TRANSITION_ROTATE == 1
            vec3 A = inpt[4*(3-j) + i].v.position.xyz;
#elif OSD_TRANSITION_ROTATE == 2
            vec3 A = inpt[4*(3-i) + (3-j)].v.position.xyz;
#elif OSD_TRANSITION_ROTATE == 3
            vec3 A = inpt[4*j + (3-i)].v.position.xyz;
#else // OSD_TRANSITION_ROTATE == 0, or non-transition patch
            vec3 A = inpt[4*i + j].v.position.xyz;
#endif
            BUCP[i] += A * B[j];
            DUCP[i] += A * D[j];
        }
    }

    vec3 WorldPos  = vec3(0);
    vec3 Tangent   = vec3(0);
    vec3 BiTangent = vec3(0);

    Univar4x4(UV.y, B, D);

    for (int k=0; k<4; ++k) {
        WorldPos  += B[k] * BUCP[k];
        Tangent   += B[k] * DUCP[k];
        BiTangent += D[k] * BUCP[k];
    }

    vec3 normal = normalize(cross(Tangent, BiTangent));

    outpt.v.position = vec4(WorldPos, 1.0f);
    outpt.v.normal = normal;
    outpt.v.tangent = Tangent;

    OSD_USER_VARYING_PER_EVAL_POINT(UV, 5, 6, 9, 10);

    outpt.v.patchCoord = inpt[0].v.patchCoord;

#if OSD_TRANSITION_ROTATE == 1
    outpt.v.patchCoord.xy = vec2(UV.y, 1.0-UV.x);
#elif OSD_TRANSITION_ROTATE == 2
    outpt.v.patchCoord.xy = vec2(1.0-UV.x, 1.0-UV.y);
#elif OSD_TRANSITION_ROTATE == 3
    outpt.v.patchCoord.xy = vec2(1.0-UV.y, UV.x);
#else // OSD_TRANNSITION_ROTATE == 0, or non-transition patch
    outpt.v.patchCoord.xy = vec2(UV.x, UV.y);
#endif

    OSD_COMPUTE_PTEX_COORD_TESSEVAL_SHADER;

    OSD_COMPUTE_PTEX_COMPATIBLE_TANGENT(OSD_TRANSITION_ROTATE);

    OSD_DISPLACEMENT_CALLBACK;

    gl_Position = (ProjectionMatrix * vec4(WorldPos, 1.0f));
}

#endif

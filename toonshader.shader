//=========================================================================================================================
// Optional
//=========================================================================================================================
HEADER
{
    Description = "Toon Shader";
    Version = 3;
}

//=========================================================================================================================
// Optional
//=========================================================================================================================
FEATURES
{
    #include "common/features.hlsl"
}

//=========================================================================================================================
// Optional
//=========================================================================================================================
MODES
{
    VrForward();                                               // Indicates this shader will be used for main rendering
    ToolsVis( S_MODE_TOOLS_VIS );                                // Ability to see in the editor
    ToolsWireframe("vr_tools_wireframe.shader");               // Allows for mat_wireframe to work
    ToolsShadingComplexity("tools_shading_complexity.shader"); // Shows how expensive drawing is in debug view
}

//=========================================================================================================================
COMMON
{
    #include "common/shared.hlsl"
}

//=========================================================================================================================

struct VertexInput
{
    #include "common/vertexinput.hlsl"
};

//=========================================================================================================================

struct PixelInput
{
    #include "common/pixelinput.hlsl"
};

//=========================================================================================================================

VS
{
    #include "common/vertex.hlsl"
    //
    // Main
    //
    PixelInput MainVs(VS_INPUT i)
    {
        PixelInput o = ProcessVertex(i);
        return FinalizeVertex(o);
    }
}

//=========================================================================================================================

PS
{
    // Combos ----------------------------------------------------------------------------------------------

    // Attributes ------------------------------------------------------------------------------------------

    // Transparency
    RenderState(BlendEnable, true);
    RenderState(SrcBlend, SRC_ALPHA);
    RenderState(DstBlend, INV_SRC_ALPHA);

    BoolAttribute(bWantsFBCopyTexture, false);
    BoolAttribute(translucent, true);

    // Code -----------------------------------------------------------------------------------------------

    //
    // Main
    //
    float4 MainPs(PixelInput i)  : SV_Target0
    {
        // Calculate cel shading
        float3 normal = normalize(i.vNormalWs.xyz);
        float3 viewDir = normalize(g_vCameraPositionWs - i.vPositionSs.xyz);
        float shade = dot(normal, viewDir);
        shade = step(0.4, shade); // Cel shading threshold

        // Apply toon shading
        float toonShade = round(shade * 5.0) / 4.0; // Quantize shading into 5 levels

        return float4(toonShade, toonShade, toonShade, 1.0); // Grayscale color based on toon shading
    }
}
HEADER
{
	Description = "Pixel Art Post Processing Shader";
	DevShader = true;
}

MODES
{
    Default();
    VrForward();
}

FEATURES
{
    #include "common/features.hlsl"
}

COMMON
{
	#include "common/shared.hlsl"
}

struct VertexInput
{
    float3 vPositionOs : POSITION < Semantic( PosXyz ); >;
    float2 vTexCoord : TEXCOORD0 < Semantic( LowPrecisionUv ); >;
};

struct PixelInput
{
	float2 uv : TEXCOORD0;
	float4 vPositionPs : SV_Position;
};

VS
{
    PixelInput MainVs( VertexInput i )
    {
        PixelInput o;
        o.vPositionPs = float4(i.vPositionOs.xy, 0.0f, 1.0f);
        o.uv = i.vTexCoord;
        return o;
    }
}

PS
{
    #include "postprocess/common.hlsl"
    #include "postprocess/functions.hlsl"

    CreateTexture2D( g_tColorBuffer ) < Attribute( "ColorBuffer" ); SrgbRead( true ); Filter( MIN_MAG_LINEAR_MIP_POINT ); AddressU( MIRROR ); AddressV( MIRROR ); >;
    CreateTexture2D( g_tGrainTexture ) < Attribute( "GrainTexture" ); SrgbRead( true ); Filter( MIN_MAG_LINEAR_MIP_POINT ); AddressU( MIRROR ); AddressV( MIRROR ); >;

    float4 FetchSceneColor( float2 vScreenUv )
    {
        return Tex2D( g_tColorBuffer, vScreenUv.xy );
    }

    float4 MainPs( PixelInput i ) : SV_Target
    {
        float2 vScreenUv = i.uv;
        float2 texSize = float2(256.0, 256.0); // adjust this to your texture size
        float2 pixelSize = 1.0 / texSize;
        float2 uvScaled = floor(vScreenUv / pixelSize) * pixelSize;
        float4 color = FetchSceneColor(uvScaled);

        // Add bit depth reduction and dithering here
        int bits = 4; // Change this to 16, 32, etc. for different bit depths
        float maxColor = pow(2, bits) - 1;
        color.rgb = floor(color.rgb * maxColor) / maxColor;

        // Advanced dithering algorithm (Ordered Dithering)
        float2 noise = (uvScaled * texSize) % 2;
        float3 dither = float3(
            (noise.x * 0.5 + 0.5) * (1.0 / maxColor),
            (noise.y * 0.5 + 0.5) * (1.0 / maxColor),
            0.0
        );

        // Add grain or noise texture
        float2 grainUv = vScreenUv * 1.0;
        float grain = (noise.x + noise.y) * 0.5;
        dither += grain * 0.025; // Adjust the intensity to control the grain amount

        color.rgb += dither;

        return color;
    }
}
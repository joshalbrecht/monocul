//--------------------------------------------------------------------------------------
// File: Tutorial07.fx
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
Texture2D txDiffuse : register( t0 );
SamplerState samLinear : register( s0 );

cbuffer cbNeverChanges : register( b0 )
{
    matrix View;
	float screenWidth;
	float screenHeight;
};

cbuffer cbChangeOnResize : register( b1 )
{
    matrix Projection;
};

cbuffer cbChangesEveryFrame : register( b2 )
{
    matrix World;
    float4 vMeshColor;
};


//--------------------------------------------------------------------------------------
struct VS_INPUT
{
    float4 Pos : POSITION;
    float2 Tex : TEXCOORD0;
};

struct PS_INPUT
{
    float4 Pos : SV_POSITION;
    float2 Tex : TEXCOORD0;
	float2 tl : TEXCOORD1;
	float2 tll : TEXCOORD2;
	float2 tr : TEXCOORD3;
	float2 trr : TEXCOORD4;
	float2 tu : TEXCOORD5;
	float2 tuu : TEXCOORD6;
	float2 td : TEXCOORD7;
	float2 tdd : TEXCOORD8;
	float2 tul : TEXCOORD9;
	float2 tur : TEXCOORD10;
	float2 tdl : TEXCOORD11;
	float2 tdr : TEXCOORD12;
};


//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
PS_INPUT VS( VS_INPUT input )
{
    PS_INPUT output = (PS_INPUT)0;
    output.Pos = mul( input.Pos, World );
    output.Pos = mul( output.Pos, View );
    output.Pos = mul( output.Pos, Projection );
    output.Tex = input.Tex;

	// Determine the floating point size of a texel for a screen with this specific width.
	float texelWSize = (1.0f / screenWidth) / 1.0f;
	float texelHSize = (1.0f / screenHeight) / 1.0f;

	// Create UV coordinates for the pixel and its neighbors
	output.tll = input.Tex + float2(texelWSize * -2.0f, texelHSize * 0.0f);
	output.trr = input.Tex + float2(texelWSize * 2.0f, texelHSize * 0.0f);
	output.tdd = input.Tex + float2(texelWSize * 0.0f, texelHSize * -2.0f);
	output.tuu = input.Tex + float2(texelWSize * 0.0f, texelHSize * 2.0f);
	output.tl = input.Tex + float2(texelWSize * -1.0f, texelHSize * 0.0f);
	output.tr = input.Tex + float2(texelWSize * 1.0f, texelHSize * 0.0f);
	output.td = input.Tex + float2(texelWSize * 0.0f, texelHSize * -1.0f);
	output.tu = input.Tex + float2(texelWSize * 0.0f, texelHSize * 1.0f);
	output.tul = input.Tex + float2(texelWSize * -1.0f, texelHSize * 1.0f);
	output.tur = input.Tex + float2(texelWSize * 1.0f, texelHSize * 1.0f);
	output.tdl = input.Tex + float2(texelWSize * -1.0f, texelHSize * -1.0f);
	output.tdr = input.Tex + float2(texelWSize * 1.0f, texelHSize * -1.0f);
    
    return output;
}


//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS( PS_INPUT input) : SV_Target
{
	float4 center = float4(screenWidth / 2.0f, screenHeight / 2.0f, 0.0f, 0.0f);
	float4 black = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float radius = 100.0f;

	float4 delta = abs(input.Pos - center);
	float dist = sqrt(delta.x*delta.x + delta.y*delta.y);
	float x = clamp(dist / radius, 0.0f, 1.0f);
	float4 textColor = txDiffuse.Sample(samLinear, input.Tex);
	//return x*textColor + (1.0f-x)*black;
	
	float weight_center, weight_neighbor, weight_corner, weight_far;
	float normalization;
	float4 color;


	// Create the weights that each neighbor pixel will contribute to the blur.
	weight_center = 1.0f;
	weight_neighbor = 0.85f;
	weight_corner = 0.7f;
	weight_far = 0.1f;

	// Create a normalized value to average the weights out a bit.
	normalization = weight_center + 4.0f * (weight_neighbor + weight_corner + weight_far);

	// Normalize the weights.
	weight_center = weight_center / normalization;
	weight_neighbor = weight_neighbor / normalization;
	weight_corner = weight_corner / normalization;
	weight_far = weight_far / normalization;

	// Initialize the color to black.
	color = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// Add the nine horizontal pixels to the color by the specific weight of each.
	color += txDiffuse.Sample(samLinear, input.tll) * weight_far;
	color += txDiffuse.Sample(samLinear, input.trr) * weight_far;
	color += txDiffuse.Sample(samLinear, input.tuu) * weight_far;
	color += txDiffuse.Sample(samLinear, input.tdd) * weight_far;
	color += txDiffuse.Sample(samLinear, input.tl) * weight_neighbor;
	color += txDiffuse.Sample(samLinear, input.tr) * weight_neighbor;
	color += txDiffuse.Sample(samLinear, input.tu) * weight_neighbor;
	color += txDiffuse.Sample(samLinear, input.td) * weight_neighbor;
	color += txDiffuse.Sample(samLinear, input.tul) * weight_corner;
	color += txDiffuse.Sample(samLinear, input.tur) * weight_corner;
	color += txDiffuse.Sample(samLinear, input.tdl) * weight_corner;
	color += txDiffuse.Sample(samLinear, input.tdr) * weight_corner;
	color += txDiffuse.Sample(samLinear, input.Tex) * weight_center;

	// Set the alpha channel to one.
	color.a = 1.0f;

	return color;
	//return textColor;
}

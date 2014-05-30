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
	float mOffset;
};


//--------------------------------------------------------------------------------------
struct VS_INPUT
{
    float4 pos : POSITION;
    float2 tex : TEXCOORD0;
};

struct PS_INPUT
{
    float4 pos : SV_POSITION;
	float2 tex : TEXCOORD0;
	float2 texCoord1 : TEXCOORD1;
	float2 texCoord2 : TEXCOORD2;
	float2 texCoord3 : TEXCOORD3;
	float2 texCoord4 : TEXCOORD4;
	float2 texCoord5 : TEXCOORD5;
	float2 texCoord6 : TEXCOORD6;
	float2 texCoord7 : TEXCOORD7;
	float2 texCoord8 : TEXCOORD8;
	float2 texCoord9 : TEXCOORD9;
};


//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
PS_INPUT VS( VS_INPUT input )
{
    PS_INPUT output = (PS_INPUT)0;

	// Change the position vector to be 4 units for proper matrix calculations.
	input.pos.w = 1.0f;

    output.pos = mul( input.pos, World );
    output.pos = mul( output.pos, View );
    output.pos = mul( output.pos, Projection );
	float texelSize;

	// Store the texture coordinates for the pixel shader.
	output.tex = input.tex;

	// Determine the floating point size of a texel for a screen with this specific width.
	texelSize = 1.0f / screenWidth;

	// Create UV coordinates for the pixel and its four horizontal neighbors on either side.
	output.texCoord1 = input.tex + float2(texelSize * -4.0f, 0.0f);
	output.texCoord2 = input.tex + float2(texelSize * -3.0f, 0.0f);
	output.texCoord3 = input.tex + float2(texelSize * -2.0f, 0.0f);
	output.texCoord4 = input.tex + float2(texelSize * -1.0f, 0.0f);
	output.texCoord5 = input.tex + float2(texelSize *  0.0f, 0.0f);
	output.texCoord6 = input.tex + float2(texelSize *  1.0f, 0.0f);
	output.texCoord7 = input.tex + float2(texelSize *  2.0f, 0.0f);
	output.texCoord8 = input.tex + float2(texelSize *  3.0f, 0.0f);
	output.texCoord9 = input.tex + float2(texelSize *  4.0f, 0.0f);
    
    return output;
}


//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS( PS_INPUT input) : SV_Target
{
	float weight0, weight1, weight2, weight3, weight4;
	float normalization;
	float4 color;


	// Create the weights that each neighbor pixel will contribute to the blur.
	weight0 = 1.0f;
	weight1 = 0.9f;
	weight2 = 0.55f;
	weight3 = 0.18f;
	weight4 = 0.1f;

	// Create a normalized value to average the weights out a bit.
	normalization = (weight0 + 2.0f * (weight1 + weight2 + weight3 + weight4));

	// Normalize the weights.
	weight0 = weight0 / normalization;
	weight1 = weight1 / normalization;
	weight2 = weight2 / normalization;
	weight3 = weight3 / normalization;
	weight4 = weight4 / normalization;

	// Initialize the color to black.
	color = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// Add the nine horizontal pixels to the color by the specific weight of each.
	color += txDiffuse.Sample(samLinear, input.texCoord1) * weight4;
	color += txDiffuse.Sample(samLinear, input.texCoord2) * weight3;
	color += txDiffuse.Sample(samLinear, input.texCoord3) * weight2;
	color += txDiffuse.Sample(samLinear, input.texCoord4) * weight1;
	color += txDiffuse.Sample(samLinear, input.texCoord5) * weight0;
	color += txDiffuse.Sample(samLinear, input.texCoord6) * weight1;
	color += txDiffuse.Sample(samLinear, input.texCoord7) * weight2;
	color += txDiffuse.Sample(samLinear, input.texCoord8) * weight3;
	color += txDiffuse.Sample(samLinear, input.texCoord9) * weight4;

	// Set the alpha channel to one.
	color.a = 1.0f;

	float4 center = float4(screenWidth / 2.0f + mOffset, screenHeight / 2.0f, 0.0f, 0.0f);
	float4 black = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float outerRadius = 300.0f;
	float innerRadius = 200.0f;

	float4 delta = abs(input.pos - center);
	float dist = sqrt(delta.x*delta.x + delta.y*delta.y);
	float x = clamp((dist-innerRadius) / (outerRadius - innerRadius), 0.0f, 1.0f);
	float4 textColor = txDiffuse.Sample(samLinear, input.texCoord5);

	//return x*textColor + (1.0f-x)*black;
	return x*color +(1.0f - x)*textColor;

	//return color;
	//return txDiffuse.Sample(samLinear, input.texCoord5);
}

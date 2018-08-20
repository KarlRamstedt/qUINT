/*=============================================================================

	ReShade 3 effect file
        visit facebook.com/MartyMcModding for news/updates

        Ambient Obscurance with Indirect Lighting "MXAO" 4.0.160 
        by Marty McFly / P.Gilcher
        part of qUINT shader library for ReShade 3

        CC BY-NC-ND 3.0 licensed.

=============================================================================*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/

#ifndef MXAO_MIPLEVEL_AO
 #define MXAO_MIPLEVEL_AO		0	//[0 to 2]      Miplevel of AO texture. 0 = fullscreen, 1 = 1/2 screen width/height, 2 = 1/4 screen width/height and so forth. Best results: IL MipLevel = AO MipLevel + 2
#endif

#ifndef MXAO_MIPLEVEL_IL
 #define MXAO_MIPLEVEL_IL		2	//[0 to 4]      Miplevel of IL texture. 0 = fullscreen, 1 = 1/2 screen width/height, 2 = 1/4 screen width/height and so forth.
#endif

#ifndef MXAO_ENABLE_IL
 #define MXAO_ENABLE_IL			0	//[0 or 1]	Enables Indirect Lighting calculation. Will cause a major fps hit.
#endif

#ifndef MXAO_SMOOTHNORMALS
 #define MXAO_SMOOTHNORMALS     0       //[0 or 1]      This feature makes low poly surfaces smoother, especially useful on older games.
#endif

#ifndef MXAO_TWO_LAYER
 #define MXAO_TWO_LAYER         0       //[0 or 1]      Splits MXAO into two separate layers that allow for both large and fine AO.
#endif

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform int MXAO_GLOBAL_SAMPLE_QUALITY_PRESET <
	ui_type = "combo";
    ui_label = "Sample Quality";
	ui_items = "Very Low  (4 samples)\0Low       (8 samples)\0Medium    (16 samples)\0High      (24 samples)\0Very High (32 samples)\0Ultra     (64 samples)\0Maximum   (255 samples)\0Auto      (variable)\0";
	ui_tooltip = "Global quality control, main performance knob. Higher radii might require higher quality.";
    ui_category = "Global";
> = 2;

uniform float MXAO_SAMPLE_RADIUS <
	ui_type = "drag";
	ui_min = 0.5; ui_max = 20.0;
    ui_label = "Sample Radius";
	ui_tooltip = "Sample radius of MXAO, higher means more large-scale occlusion with less fine-scale details.";  
    ui_category = "Global";      
> = 2.5;

uniform float MXAO_SAMPLE_NORMAL_BIAS <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.8;
    ui_label = "Normal Bias";
	ui_tooltip = "Occlusion Cone bias to reduce self-occlusion of surfaces that have a low angle to each other.";
    ui_category = "Global";
> = 0.2;

uniform float MXAO_GLOBAL_RENDER_SCALE <
	ui_type = "drag";
    ui_label = "Render Size Scale";
	ui_min = 0.50; ui_max = 1.00;
    ui_tooltip = "Factor of MXAO resolution, lower values greatly reduce performance overhead but decrease quality.\n1.0 = MXAO is computed in original resolution\n0.5 = MXAO is computed in 1/2 width 1/2 height of original resolution\n...";
    ui_category = "Global";
> = 1.0;

uniform float MXAO_SSAO_AMOUNT <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 4.00;
    ui_label = "Ambient Occlusion Amount";        
	ui_tooltip = "Intensity of AO effect. Can cause pitch black clipping if set too high.";
    ui_category = "Ambient Occlusion";
> = 1.00;

#if(MXAO_ENABLE_IL != 0)
uniform float MXAO_SSIL_AMOUNT <
    ui_type = "drag";
    ui_min = 0.00; ui_max = 12.00;
    ui_label = "Indirect Lighting Amount";
    ui_tooltip = "Intensity of IL effect. Can cause overexposured white spots if set too high.";
    ui_category = "Indirect Lighting";
> = 4.00;

uniform float MXAO_SSIL_SATURATION <
    ui_type = "drag";
    ui_min = 0.00; ui_max = 3.00;
    ui_label = "Indirect Lighting Saturation";
    ui_tooltip = "Controls color saturation of IL effect.";
    ui_category = "Indirect Lighting";
> = 1.00;
#endif

#if (MXAO_TWO_LAYER != 0)
    uniform float MXAO_SAMPLE_RADIUS_SECONDARY <
        ui_type = "drag";
        ui_min = 0.1; ui_max = 1.00;
        ui_label = "Fine AO Scale";
        ui_tooltip = "Multiplier of Sample Radius for fine geometry. A setting of 0.5 scans the geometry at half the radius of the main AO.";
        ui_category = "Double Layer";
    > = 0.2;

    uniform float MXAO_AMOUNT_FINE <
        ui_type = "drag";
        ui_min = 0.00; ui_max = 1.00;
        ui_label = "Fine AO intensity multiplier";
        ui_tooltip = "Intensity of small scale AO / IL.";
        ui_category = "Double Layer";
    > = 1.0;

    uniform float MXAO_AMOUNT_COARSE <
        ui_type = "drag";
        ui_min = 0.00; ui_max = 1.00;
        ui_label = "Coarse AO intensity multiplier";
        ui_tooltip = "Intensity of large scale AO / IL.";
        ui_category = "Double Layer";
    > = 1.0;
#endif

uniform int MXAO_BLEND_TYPE <
	ui_type = "drag";
	ui_min = 0; ui_max = 3;
    ui_label = "Blending Mode";
	ui_tooltip = "Different blending modes for merging AO/IL with original color.\0Blending mode 0 matches formula of MXAO 2.0 and older.";
    ui_category = "Blending";
> = 0;

uniform float MXAO_FADE_DEPTH_START <
	ui_type = "drag";
    ui_label = "Fade Out Start";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Distance where MXAO starts to fade out. 0.0 = camera, 1.0 = sky. Must be less than Fade Out End.";
    ui_category = "Blending";
> = 0.05;

uniform float MXAO_FADE_DEPTH_END <
	ui_type = "drag";
    ui_label = "Fade Out End";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Distance where MXAO completely fades out. 0.0 = camera, 1.0 = sky. Must be greater than Fade Out Start.";
    ui_category = "Blending";
> = 0.4;

uniform int MXAO_DEBUG_VIEW_ENABLE <
	ui_type = "combo";
    ui_label = "Enable Debug View";
	ui_items = "None\0AO/IL channel\0Normal vectors\0";
	ui_tooltip = "Different debug outputs";
    ui_category = "Debug";
> = 0;

/*=============================================================================
	Textures, Samplers, Globals
=============================================================================*/

#include "qUINT_common.fxh"

texture2D MXAO_ColorTex 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; MipLevels = 3+MXAO_MIPLEVEL_IL;};
texture2D MXAO_DepthTex 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = R16F;  MipLevels = 3+MXAO_MIPLEVEL_AO;};
texture2D MXAO_NormalTex	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; MipLevels = 3+MXAO_MIPLEVEL_IL;};

sampler2D sMXAO_ColorTex	{ Texture = MXAO_ColorTex;	};
sampler2D sMXAO_DepthTex	{ Texture = MXAO_DepthTex;	};
sampler2D sMXAO_NormalTex	{ Texture = MXAO_NormalTex;	};

#if(MXAO_ENABLE_IL != 0)
 #define BLUR_COMP_SWIZZLE xyzw
#else
 #define BLUR_COMP_SWIZZLE w
#endif

/*=============================================================================
	Vertex Shader
=============================================================================*/

struct MXAO_VSOUT
{
	float4                  vpos        : SV_Position;
    float4                  uv          : TEXCOORD0;
    nointerpolation float   samples     : TEXCOORD1;
    nointerpolation float3  uvtoviewADD : TEXCOORD4;
    nointerpolation float3  uvtoviewMUL : TEXCOORD5;
};

MXAO_VSOUT VS_MXAO(in uint id : SV_VertexID)
{
    MXAO_VSOUT MXAO;

    MXAO.uv.x = (id == 2) ? 2.0 : 0.0;
    MXAO.uv.y = (id == 1) ? 2.0 : 0.0;
    MXAO.uv.zw = MXAO.uv.xy / MXAO_GLOBAL_RENDER_SCALE;
    MXAO.vpos = float4(MXAO.uv.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);

    MXAO.samples   = 8;

    if(     MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 0) { MXAO.samples = 4;     }
    else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 1) { MXAO.samples = 8;     }
    else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 2) { MXAO.samples = 16;    }
    else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 3) { MXAO.samples = 24;    }
    else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 4) { MXAO.samples = 32;    }
    else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 5) { MXAO.samples = 64;    }
    else if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 6) { MXAO.samples = 255;   }
    
    MXAO.uvtoviewADD = float3(-1.0,-1.0,1.0);
    MXAO.uvtoviewMUL = float3(2.0,2.0,0.0);

/*  //uncomment to enable perspective-correct position recontruction. Minor difference for common FoV's
    static const float FOV = 70.0; //vertical FoV

    MXAO.uvtoviewADD = float3(-tan(radians(FOV * 0.5)).xx,1.0) * qUINT::ASPECT_RATIO;
    MXAO.uvtoviewMUL = float3(-2.0 * MXAO.uvtoviewADD.xy,0.0);
*/
    return MXAO;
}

/*=============================================================================
	Functions
=============================================================================*/

float3 get_position_from_uv(in float2 uv, in MXAO_VSOUT MXAO)
{
    return (uv.xyx * MXAO.uvtoviewMUL + MXAO.uvtoviewADD) * qUINT::linear_depth(uv) * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
}

float3 get_position_from_uv_mipmapped(in float2 uv, in MXAO_VSOUT MXAO, in int miplevel)
{
    return (uv.xyx * MXAO.uvtoviewMUL + MXAO.uvtoviewADD) * tex2Dlod(sMXAO_DepthTex, float4(uv.xyx, miplevel)).x;
}

void spatial_sample_weight(in float4 tempkey, in float4 centerkey, in float surfacealignment, inout float weight)
{
    weight = saturate(rcp(surfacealignment) - abs(tempkey.w - centerkey.w)) * saturate(dot(tempkey.xyz, centerkey.xyz) * 16 - 15);
    weight = saturate(weight * 4.0);
}

void spatial_sample_key(in float2 uv, in float inputscale, in sampler inputsampler, inout float4 tempsample, inout float4 key)
{
    float4 lodcoord = float4(uv.xy, 0, 0);
    tempsample = tex2Dlod(inputsampler, lodcoord * inputscale);
    key = float4(tex2Dlod(sMXAO_NormalTex, lodcoord).xyz * 2.0 - 1.0, tex2Dlod(sMXAO_DepthTex, lodcoord).x);
}

float4 blur_filter(in MXAO_VSOUT MXAO, in sampler inputsampler, in float inputscale, in float radius, in int blursteps, in int passid)
{
    float4 tempsample;
    float4 centerkey, tempkey;
    float  centerweight = 1.0, tempweight;
    float4 blurcoord = 0.0;

    spatial_sample_key(MXAO.uv.xy, inputscale, inputsampler, tempsample, centerkey);
    float surfacealignment = saturate(-dot(centerkey.xyz, normalize(float3(MXAO.uv.xy * 2.0 - 1.0, 1.0) * centerkey.w)));

    float4 samplesum = tempsample.BLUR_COMP_SWIZZLE;
    [branch]
    if(MXAO.samples == 255) return samplesum.BLUR_COMP_SWIZZLE;
    float4 samplesum_noweight = samplesum;
    float2 bluroffsets[8] = {float2(1.5,0.5),float2(-1.5,-0.5),float2(-0.5,1.5),float2(0.5,-1.5),
                             float2(1.5,2.5),float2(-1.5,-2.5),float2(-2.5,1.5),float2(2.5,-1.5)};

    float2 scaled_radius = qUINT::PIXEL_SIZE * radius / inputscale;

    [unroll]
    for(int i = 0; i < blursteps; i++)
    {
        float2 sampleCoord = MXAO.uv.xy + bluroffsets[i] * scaled_radius;

        spatial_sample_key(sampleCoord, inputscale, inputsampler, tempsample, tempkey);
        spatial_sample_weight(tempkey, centerkey, surfacealignment, tempweight);

        samplesum += tempsample.BLUR_COMP_SWIZZLE * tempweight;
        samplesum_noweight += tempsample.BLUR_COMP_SWIZZLE;
        centerweight += tempweight;
    }

    samplesum_noweight.BLUR_COMP_SWIZZLE /= 1 + blursteps;
    samplesum.BLUR_COMP_SWIZZLE /= centerweight;
    return lerp(samplesum.BLUR_COMP_SWIZZLE, samplesum_noweight.BLUR_COMP_SWIZZLE, centerweight < 1.5);
}

void sample_parameter_setup(in MXAO_VSOUT MXAO, in float scaled_depth, in float layer_id, out float scaled_radius, out float falloff_factor)
{
    scaled_radius  = 0.25 * MXAO_SAMPLE_RADIUS / (MXAO.samples * (scaled_depth + 2.0));
    falloff_factor = -1.0/(MXAO_SAMPLE_RADIUS * MXAO_SAMPLE_RADIUS);

    #if(MXAO_TWO_LAYER != 0)
        scaled_radius  *= lerp(1.0, MXAO_SAMPLE_RADIUS_SECONDARY + 1e-6, layer_id);
        falloff_factor *= lerp(1.0, 1.0 / (MXAO_SAMPLE_RADIUS_SECONDARY * MXAO_SAMPLE_RADIUS_SECONDARY + 1e-6), layer_id);
    #endif
}

void smooth_normals(inout float3 normal, in float3 position, in MXAO_VSOUT MXAO)
{
    float2 scaled_radius = 0.018 / position.z * qUINT::ASPECT_RATIO;
    float3 neighbour_normal[4] = {normal, normal, normal, normal};

    [unroll]
    for(int i = 0; i < 4; i++)
    {
        float2 direction;
        sincos(6.28318548 * 0.25 * i, direction.y, direction.x);

        [unroll]
        for(int direction_step = 1; direction_step <= 5; direction_step++)
        {
            float search_radius = exp2(direction_step);
            float2 sample_uv = MXAO.uv.zw + direction * search_radius * scaled_radius;

            float3 temp_normal = tex2Dlod(sMXAO_NormalTex, float4(sample_uv, 0, 0)).xyz * 2.0 - 1.0;
            float3 temp_position = get_position_from_uv_mipmapped(sample_uv, MXAO, 0);

            float3 position_delta = temp_position - position;
            float distance_weight = saturate(1.0 - dot(position_delta, position_delta) * 20.0 / search_radius);
            float normal_angle = dot(normal, temp_normal);
            float angle_weight = smoothstep(0.3, 0.98, normal_angle) * smoothstep(1.0, 0.98, normal_angle); //only take normals into account that are NOT equal to the current normal.

            float total_weight = saturate(3.0 * distance_weight * angle_weight / search_radius);

            neighbour_normal[i] = lerp(neighbour_normal[i], temp_normal, total_weight);
        }
    }

    normal = normalize(neighbour_normal[0] + neighbour_normal[1] + neighbour_normal[2] + neighbour_normal[3]);
}

/*=============================================================================
	Pixel Shaders
=============================================================================*/

void PS_InputBufferSetup(in MXAO_VSOUT MXAO, out float4 color : SV_Target0, out float4 depth : SV_Target1, out float4 normal : SV_Target2)
{
    float3 single_pixel_offset = float3(qUINT::PIXEL_SIZE.xy, 0);

	float3 position                 =               get_position_from_uv(MXAO.uv.xy, MXAO);
	float3 position_delta_x1 	 = - position + get_position_from_uv(MXAO.uv.xy + single_pixel_offset.xz, MXAO);
	float3 position_delta_x2 	 =   position - get_position_from_uv(MXAO.uv.xy - single_pixel_offset.xz, MXAO);
	float3 position_delta_y1 	 = - position + get_position_from_uv(MXAO.uv.xy + single_pixel_offset.zy, MXAO);
	float3 position_delta_y2 	 =   position - get_position_from_uv(MXAO.uv.xy - single_pixel_offset.zy, MXAO);

	position_delta_x1 = lerp(position_delta_x1, position_delta_x2, abs(position_delta_x1.z) > abs(position_delta_x2.z));
	position_delta_y1 = lerp(position_delta_y1, position_delta_y2, abs(position_delta_y1.z) > abs(position_delta_y2.z));

    float sample_jitter = dot(floor(MXAO.vpos.xy % 4 + 0.1), float2(0.0625, 0.25)) + 0.0625;

	normal  = float4(normalize(cross(position_delta_y1, position_delta_x1)) * 0.5 + 0.5, sample_jitter);
    color 	= tex2D(qUINT::sBackBufferTex, MXAO.uv.xy);
	depth 	= qUINT::linear_depth(MXAO.uv.xy) * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;    
}

void PS_StencilSetup(in MXAO_VSOUT MXAO, out float4 color : SV_Target0)
{        
    if(    qUINT::linear_depth(MXAO.uv.zw) >= MXAO_FADE_DEPTH_END
        || 0.25 * 0.5 * MXAO_SAMPLE_RADIUS / (tex2D(sMXAO_DepthTex, MXAO.uv.zw).x + 2.0) * BUFFER_HEIGHT < 1.0
        || MXAO.uv.z > 1.0
        || MXAO.uv.w > 1.0
        ) discard;

    color = 1.0;
}

void PS_AmbientObscurance(in MXAO_VSOUT MXAO, out float4 color : SV_Target0)
{
    color = 0.0;

	float3 position = get_position_from_uv_mipmapped(MXAO.uv.zw, MXAO, 0);
    float4 normal = tex2D(sMXAO_NormalTex, MXAO.uv.zw);
    normal.xyz = normal.xyz * 2.0 - 1.0;

    float  layer_id = (MXAO.vpos.x + MXAO.vpos.y) % 2.0;

#if(MXAO_SMOOTHNORMALS != 0)
    smooth_normals(normal.xyz, position, MXAO);
#endif
    float linear_depth = position.z / RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;        
    position += normal.xyz * linear_depth;

    if(MXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 7) MXAO.samples = 2 + floor(0.05 * MXAO_SAMPLE_RADIUS / linear_depth);

    float scaled_radius;
    float falloff_factor;
    sample_parameter_setup(MXAO, position.z, layer_id, scaled_radius, falloff_factor);

    float2 sample_uv, sample_direction;
    sincos(2.3999632 * 16 * normal.w, sample_direction.x, sample_direction.y); //2.3999632 * 16
    sample_direction *= scaled_radius;   

    [loop]
    for(int i = 0; i < MXAO.samples; i++)
    {                    
        sample_uv = MXAO.uv.zw + sample_direction.xy * qUINT::ASPECT_RATIO * (i + normal.w);   
        sample_direction.xy = mul(sample_direction.xy, float2x2(0.76465, -0.64444, 0.64444, 0.76465)); //cos/sin 2.3999632 * 16            

        float sample_mip = saturate(scaled_radius * i * 20.0) * 3.0;
           
    	float3 occlusion_vector = -position + get_position_from_uv_mipmapped(sample_uv, MXAO, sample_mip + MXAO_MIPLEVEL_AO);                
        float  occlusion_distance_squared = dot(occlusion_vector, occlusion_vector);
        float  occlusion_normal_angle = dot(occlusion_vector, normal.xyz) * rsqrt(occlusion_distance_squared);

        float sample_occlusion = saturate(1.0 + falloff_factor * occlusion_distance_squared) * saturate(occlusion_normal_angle - MXAO_SAMPLE_NORMAL_BIAS);
#if(MXAO_ENABLE_IL != 0)
        [branch]
        if(sample_occlusion > 0.1)
        {
                float3 sample_indirect_lighting = tex2Dlod(sMXAO_ColorTex, float4(sample_uv, 0, sample_mip + MXAO_MIPLEVEL_IL)).xyz;
                float3 sample_normal = tex2Dlod(sMXAO_NormalTex, float4(sample_uv, 0, sample_mip + MXAO_MIPLEVEL_IL)).xyz * 2.0 - 1.0;
                sample_indirect_lighting *= saturate(dot(-sample_normal, occlusion_vector) * rsqrt(occlusion_distance_squared) * 4.0) * saturate(1.0 + falloff_factor * occlusion_distance_squared * 0.25);
                color += float4(sample_indirect_lighting, sample_occlusion);
        }
#else
        color.w += sample_occlusion;
#endif
    }

    color = saturate(color / ((1.0 - MXAO_SAMPLE_NORMAL_BIAS) * MXAO.samples) * 2.0);
    color = sqrt(color.BLUR_COMP_SWIZZLE); //AO denoise

#if(MXAO_TWO_LAYER != 0)
    color *= lerp(MXAO_AMOUNT_COARSE, MXAO_AMOUNT_FINE, layer_id); 
#endif
}

void PS_SpatialFilter1(in MXAO_VSOUT MXAO, out float4 color : SV_Target0)
{
    color = blur_filter(MXAO, qUINT::sCommonTex0, MXAO_GLOBAL_RENDER_SCALE, 1, 8, 0);
}

void PS_SpatialFilter2(MXAO_VSOUT MXAO, out float4 color : SV_Target0)
{
    float4 ssil_ssao = blur_filter(MXAO, qUINT::sCommonTex1, 1, 0.75 / MXAO_GLOBAL_RENDER_SCALE, 4, 1);
    ssil_ssao *= ssil_ssao; //AO denoise

	color = tex2D(sMXAO_ColorTex, MXAO.uv.xy);

    static const float3 lumcoeff = float3(0.2126, 0.7152, 0.0722);
    float scenedepth = qUINT::linear_depth(MXAO.uv.xy);        
    float colorgray = dot(color.rgb, lumcoeff);
    float blendfact = 1.0 - colorgray;

#if(MXAO_ENABLE_IL != 0)
	ssil_ssao.xyz  = lerp(dot(ssil_ssao.xyz, lumcoeff), ssil_ssao.xyz, MXAO_SSIL_SATURATION) * MXAO_SSIL_AMOUNT * 2.0;
#else
    ssil_ssao.xyz = 0.0;
#endif

	ssil_ssao.w  = 1.0 - pow(1.0 - ssil_ssao.w, MXAO_SSAO_AMOUNT * 4.0);
    ssil_ssao    *= 1.0 - smoothstep(MXAO_FADE_DEPTH_START, MXAO_FADE_DEPTH_END, scenedepth * float4(2.0, 2.0, 2.0, 1.0));

    if(MXAO_BLEND_TYPE == 0)
    {
        color.rgb -= (ssil_ssao.www - ssil_ssao.xyz) * blendfact * color.rgb;
    }
    else if(MXAO_BLEND_TYPE == 1)
    {
        color.rgb = color.rgb * saturate(1.0 - ssil_ssao.www * blendfact * 1.2) + ssil_ssao.xyz * blendfact * colorgray * 2.0;
    }
    else if(MXAO_BLEND_TYPE == 2)
    {
        float colordiff = saturate(2.0 * distance(normalize(color.rgb + 1e-6),normalize(ssil_ssao.rgb + 1e-6)));
        color.rgb = color.rgb + ssil_ssao.rgb * lerp(color.rgb, dot(color.rgb, 0.3333), colordiff) * blendfact * blendfact * 4.0;
        color.rgb = color.rgb * (1.0 - ssil_ssao.www * (1.0 - dot(color.rgb, lumcoeff)));
    }
    else if(MXAO_BLEND_TYPE == 3)
    {
        color.rgb *= color.rgb;
        color.rgb -= (ssil_ssao.www - ssil_ssao.xyz) * color.rgb;
        color.rgb = sqrt(color.rgb);
    }

    if(MXAO_DEBUG_VIEW_ENABLE == 1)
    {
        color.rgb = max(0.0, 1.0 - ssil_ssao.www + ssil_ssao.xyz);
        color.rgb *= (MXAO_ENABLE_IL != 0) ? 0.5 : 1.0;
    }
    else if(MXAO_DEBUG_VIEW_ENABLE == 2)
    {      
        color.rgb = tex2D(sMXAO_NormalTex, MXAO.uv.xy).xyz;
    }
       
    color.a = 1.0;        
}

/*=============================================================================
	Techniques
=============================================================================*/

technique MXAO
{
    pass
	{
		VertexShader = VS_MXAO;
		PixelShader  = PS_InputBufferSetup;
		RenderTarget0 = MXAO_ColorTex;
		RenderTarget1 = MXAO_DepthTex;
		RenderTarget2 = MXAO_NormalTex;
	}
    pass
    {
        VertexShader = VS_MXAO;
		PixelShader  = PS_StencilSetup;
        /*Render Target is Backbuffer*/
        ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = REPLACE;
        StencilRef = 1;
    }
    pass
    {
        VertexShader = VS_MXAO;
        PixelShader  = PS_AmbientObscurance;
        RenderTarget = qUINT::CommonTex0;
        ClearRenderTargets = true;
        StencilEnable = true;
        StencilPass = KEEP;
        StencilFunc = EQUAL;
        StencilRef = 1;
    }
    pass
	{
		VertexShader = VS_MXAO;
		PixelShader  = PS_SpatialFilter1;
        RenderTarget = qUINT::CommonTex1;
	}
	pass
	{
		VertexShader = VS_MXAO;
		PixelShader  = PS_SpatialFilter2;
        /*Render Target is Backbuffer*/
	}
}
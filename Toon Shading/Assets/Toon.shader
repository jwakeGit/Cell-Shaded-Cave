// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Roystan/Toon"
{
	Properties
	{
		_Color("Color", Color) = (0.5, 0.65, 1, 1)
		_MainTex("Main Texture", 2D) = "white" {}
	//Ambient light: Light that bounces off the surfaces of objects in the area
	//and is scattered into the atmostphere
		[HDR]
		_AmbientColor("Ambient Color", Color) = (0.4, 0.4, 0.4, 1)
		_SpecularColor("Specular Color", Color) = (0.9, 0.9, 0.9, 1)
		_Glossiness("Glossiness", Float) = 32
		_RimColor("Rim Color", Color) = (1, 1, 1, 1)
		_RimAmount("Rim Amount", Range(0, 1)) = 0.716
		_RimThreshold("Rim Threshold", Range(0, 1)) = 0.1 //Controls how much the rim extends over the sphere
	}
		SubShader
	{
		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
				//"PassFlags" = "OnlyDirectional"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase //Used for shadows


			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			float4 _Color;
			float4 _AmbientColor;
			float _Glossiness;
			float4 _SpecularColor;
			float4 _RimColor;
			float _RimAmount;
			float _RimThreshold;

			struct appdata
			{
				float3 normal : NORMAL;

				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
			};

			struct v2f
			{
				float3 worldNormal : NORMAL;
				float3 viewDir : TEXCOORD1;

				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;

				//float3 vertexLighting : TEXCOORD2;

				SHADOW_COORDS(2)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.viewDir = WorldSpaceViewDir(v.vertex);

				TRANSFER_SHADOW(o)

				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				if (_WorldSpaceLightPos0.w == 0)
				{
					//Shadow
					float3 normal = normalize(i.worldNormal);
					float NdotL = dot(_WorldSpaceLightPos0, normal);

					//Additional lights?
					//Might need a second pass

					float shadow = SHADOW_ATTENUATION(i);
					float lightIntensity = smoothstep(0, 0.01, NdotL * shadow); //Helps turn the regular shading to toon shading
																				//Smoothstep helps get rid of jaggedness
					float4 light = lightIntensity * _LightColor0;

					//Specular Reflection
					float3 viewDir = normalize(i.viewDir);
					float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
					float NdotH = dot(normal, halfVector);
					float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
					float specularIntensitySmooth = smoothstep(0.005, 0.05, specularIntensity);
					float4 specular = specularIntensitySmooth * _SpecularColor;

					float4 rimDot = 1 - dot(viewDir, normal);
					float rimIntensity = rimDot * pow(NdotL, _RimThreshold); //This is multiplying by the light refelection
					rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
					float4 rim = rimIntensity * _RimColor;

					float4 sample = tex2D(_MainTex, i.uv);

					return _Color * sample * (_AmbientColor + light + specular + rim)/* + float4(i.vertexLighting, 1.0)*/;
				}
				else
				{
					float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - i.pos.xyz;
					float distance = length(vertexToLightSource);
					float attenuation = 1.0 / distance;
					float3 lightDirection = normalize(vertexToLightSource);

					//Shadow
					float3 normal = normalize(i.worldNormal);
					float NdotL = dot(_WorldSpaceLightPos0, normal);

					//Additional lights?
					//Might need a second pass

					float shadow = SHADOW_ATTENUATION(i);
					float lightIntensity = smoothstep(0, 0.01, NdotL * shadow); //Helps turn the regular shading to toon shading
																				//Smoothstep helps get rid of jaggedness
					float4 light = lightIntensity * _LightColor0;

					//Specular Reflection
					float3 viewDir = normalize(i.viewDir);
					float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
					float NdotH = dot(normal, halfVector);
					float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
					float specularIntensitySmooth = smoothstep(0.005, 0.05, specularIntensity);
					float4 specular = specularIntensitySmooth * _SpecularColor;

					float4 rimDot = 1 - dot(viewDir, normal);
					float rimIntensity = rimDot * pow(NdotL, _RimThreshold); //This is multiplying by the light refelection
					rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
					float4 rim = rimIntensity * _RimColor;

					float4 sample = tex2D(_MainTex, i.uv);

					return _Color * sample * (_AmbientColor + light + specular + rim);
				}
			}
			ENDCG
		}

		
		Pass //For additional lights
		{
			Tags
			{
				"LightMode" = "ForwardAdd"
				//"PassFlags" = "OnlyDirectional"
			}
			Blend One One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase //Used for shadows


			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			float4 _Color;
			float4 _AmbientColor;
			float _Glossiness;
			float4 _SpecularColor;
			float4 _RimColor;
			float _RimAmount;
			float _RimThreshold;

			struct appdata
			{
				float3 normal : NORMAL;

				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
			};

			struct v2f
			{
				float3 worldNormal : NORMAL;
				float3 viewDir : TEXCOORD1;

				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;

				//float3 vertexLighting : TEXCOORD2;

				SHADOW_COORDS(2)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = mul(unity_ObjectToWorld, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.viewDir = WorldSpaceViewDir(v.vertex);

				TRANSFER_SHADOW(o)

				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				
				float3 normal = normalize(i.worldNormal);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.uv.xyz);
				float attenuation;
				float3 lightDirection;

				if (_WorldSpaceLightPos0.w == 0)
				{
					attenuation = 1.0;
					lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				}
				else
				{
					float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - i.uv.xyz;
					float distance = length(vertexToLightSource);
					float r = 1/_LightPositionRange.w; //This gets the range of the point light

					attenuation = 1.0 - distance/r; //Attenuation is the distance to the light source, proportional to the range

					lightDirection = normalize(vertexToLightSource);

					//float r = unity_LightAtten[8];
				}

				float NdotL = dot(lightDirection, normal);
				float shadow = SHADOW_ATTENUATION(i);
				float lightIntensity = smoothstep(0, 0.01, NdotL * shadow); //Helps turn the regular shading to toon shading
																			//Smoothstep helps get rid of jaggedness
				float4 light = lightIntensity * _LightColor0;
				
				//Specular and Rim Lighting
				float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
				float NdotH = dot(normal, halfVector);
				float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
				float specularIntensitySmooth = smoothstep(0.005, 0.05, specularIntensity);
				float4 specular = specularIntensitySmooth * _SpecularColor;

				float4 rimDot = 1 - dot(viewDir, normal);
				float rimIntensity = rimDot * pow(NdotL, _RimThreshold); //This is multiplying by the light refelection
				rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
				float4 rim = rimIntensity * _RimColor;

				//Final result
				float4 sample = tex2D(_MainTex, i.uv);

				if (attenuation > 0.6)
				{
					attenuation = 1.0;
				}
				else if(attenuation > 0.2)
				{
					attenuation = 0.5;
				}
				else
				{
					attenuation = 0;
				}

				return attenuation * sample * _Color * (_AmbientColor + light + specular + rim);
			}
			ENDCG
		}
		// Insert just after the closing curly brace of the existing Pass.
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}
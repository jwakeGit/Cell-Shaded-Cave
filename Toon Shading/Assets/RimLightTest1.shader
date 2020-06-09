// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'


Shader "Custom/RimLight"{


	Properties
	{
		_Color("Color", Color) = (0.5, 0.65, 1, 1)
		_MainTex("Main Texture", 2D) = "white" {}
	//Ambient light: Light that bounces off the surfaces of objects in the area
	//and is scattered into the atmostphere
		[HDR]
		_AmbientColor("Ambient Color", Color) = (0.4, 0.4, 0.4, 1)
		_SpecularColor("Specular Color", Color) = (0.9, 0.9, 0.9, 1)
		_Shininess ("Shininess", Float) = 10
		_Glossiness("Glossiness", Float) = 32
		_RimColor("Rim Color", Color) = (1, 1, 1, 1)
		_RimAmount("Rim Amount", Range(0, 1)) = 0.716
		_RimThreshold("Rim Threshold", Range(0, 1)) = 0.1 //Controls how much the rim extends over the sphere
		_RimPower ("Rim Power", Range(0.1, 10.0)) = 3.0

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

				/*for (int i = 0; i < 4; i++)
				{
					float4 lightPos = float4(unity_4LightPosX0[i],
						unity_4LightPosY0[i],
						unity_4LightPosZ0[i], 1.0);

					float3 vertexToLightSource =
						lightPos.xyz - o.pos.xyz;
					float3 lightDirection = normalize(vertexToLightSource);
					float squaredDistance =
						dot(vertexToLightSource, vertexToLightSource);
					float attenuation = 1.0 / (1.0 +
						unity_4LightAtten0[i] * squaredDistance);
					float3 diffuseReflection = attenuation
						* unity_LightColor[i].rgb * _Color.rgb
						* max(0.0, dot(o.worldNormal, lightDirection));

					o.vertexLighting =
						o.vertexLighting + diffuseReflection;
				}*/

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
			uniform float _RimPower;
			uniform float _Shininess;

			

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

			
			struct vertexInput{
				float4 vertex : POSITION;
				float3 normal : NORMAL; 
			};

			struct vertexOutput{
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
			};
			

			sampler2D _MainTex;
			float4 _MainTex_ST;
			/*
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
				
				

				//Final result
				float4 sample = tex2D(_MainTex, i.uv);
				//return _Color * sample * (_AmbientColor + light) * attenuation;

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

				return _LightColor0 * attenuation * sample * _Color * lightIntensity;
			}
			*/

			
			//vertex function
			vertexOutput vert(vertexInput v){
				vertexOutput o;
				o.posWorld = mul( unity_ObjectToWorld, v.vertex);
				o.normalDir = normalize( mul( float4( v.normal, 0.0), unity_WorldToObject).xyz);
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}
			

			
			//fragment function
			float4 frag(vertexOutput i) : COLOR
			{
				float3 normalDirection = i.normalDir;	
				float3 viewDirection = normalize( _WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				float3 lightDirection = normalize( _WorldSpaceLightPos0.xyz);
				float atten = 1.0;

				float3 diffuseReflection = atten * 	_LightColor0.xyz * saturate( dot( normalDirection, 	lightDirection));
				float3 specularReflection = atten * _LightColor0.xyz * saturate( dot( normalDirection, 	lightDirection)) * pow( saturate(dot(reflect(-	lightDirection, normalDirection),viewDirection)), _Shininess);
		
				float rim = 1 - saturate( dot( normalize(viewDirection), normalDirection));
				float3 rimLighting = atten * 	_LightColor0.xyz * _RimColor * 	saturate(dot(normalDirection,lightDirection))* pow(rim, _RimPower);

				float3 lightFinal = rimLighting + 	diffuseReflection + specularReflection + UNITY_LIGHTMODEL_AMBIENT.rgb;

				return float4(lightFinal * _Color.xyz, 1.0);
					
			}
			
			ENDCG
		}
		
		/*
		Pass
		{

			Tags
			{
				"LightMode" = "ForwardAdd"
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
			uniform float _RimPower;
			uniform float _Shininess;

			struct vertexInput{
				float4 vertex : POSITION;
				float3 normal : NORMAL; 
			};

			struct vertexOutput{
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
			};


			//vertex function
			vertexOutput vert(vertexInput v){
				vertexOutput o;
				o.posWorld = mul( unity_ObjectToWorld, v.vertex);
				o.normalDir = normalize( mul( float4( v.normal, 0.0), unity_WorldToObject).xyz);
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}

			//fragment function
			float4 frag(vertexOutput i) : COLOR
			{
				float3 normalDirection = i.normalDir;	
				float3 viewDirection = normalize( _WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				float3 lightDirection = normalize( _WorldSpaceLightPos0.xyz);
				float atten = 1.0;

				float3 diffuseReflection = atten * 	_LightColor0.xyz * saturate( dot( normalDirection, 	lightDirection));
				float3 specularReflection = atten * _LightColor0.xyz * saturate( dot( normalDirection, 	lightDirection)) * pow( saturate(dot(reflect(-	lightDirection, normalDirection),viewDirection)), _Shininess);
		
				float rim = 1 - saturate( dot( normalize(viewDirection), normalDirection));
				float3 rimLighting = atten * 	_LightColor0.xyz * _RimColor * 	saturate(dot(normalDirection,lightDirection))* pow(rim, _RimPower);

				float3 lightFinal = rimLighting + 	diffuseReflection + specularReflection + UNITY_LIGHTMODEL_AMBIENT.rgb;

				return float4(lightFinal * _Color.xyz, 1.0);
					
			}

			ENDCG


		}
		*/
		// Insert just after the closing curly brace of the existing Pass.
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}
	
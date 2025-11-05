Includes = {
	"buttonstate.fxh"
	"sprite_animation.fxh"
}

PixelShader =
{
	Samplers =
	{
		MapTexture =
		{
			Index = 0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
			MipMapLodBias = -0.8
		}
		MaskTexture =
		{
			Index = 1
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
		AnimatedTexture =
		{
			Index = 2
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Wrap"
			AddressV = "Wrap"
		}
		MaskTexture2 =
		{
			Index = 3
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
		AnimatedTexture2 =
		{
			Index = 4
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Wrap"
			AddressV = "Wrap"
		}
		#This masking texture is the ACTUAL masking texture. The others are for animation
		MaskingTexture =
		{
			Index = 5
			MagFilter = "Point"
			MinFilter = "Point"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}




	}
}


VertexStruct VS_OUTPUT
{
	float4  vPosition : PDX_POSITION;
	float2  vTexCoord : TEXCOORD0;
@ifdef ANIMATED
	float4  vAnimatedTexCoord : TEXCOORD1;
@endif
@ifdef MASKING
	float2  vMaskingTexCoord : TEXCOORD2;
@endif
};


VertexShader =
{
	MainCode VertexShader
	[[
		VS_OUTPUT main(const VS_INPUT v )
		{
		    VS_OUTPUT Out;
		    Out.vPosition  = mul( WorldViewProjectionMatrix, float4( v.vPosition.xyz, 1 ) );
		
		    Out.vTexCoord = v.vTexCoord;
		
		    return Out;
		}
	]]
}

PixelShader =
{
	MainCode PixelShaderUp
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
			
			float value = NextOffset.x;
			
			//Input is AB with A being the starting of the three frame and B being the end (1-3)
			float firstVal = floor(value/10.f);
			float secondVal = floor(value) - (firstVal*10.f);
			
			float vTime = Time - AnimationTime;
			
			firstVal -= 1;
			secondVal -= 1;
			
			if(firstVal == 2)
			{
				firstVal *= 0.442;
				firstVal -= 0.0025;
			}
			else{
				firstVal *= 0.442;
			}
			
			if(secondVal == 2)
			{
				secondVal *= 0.442;
				secondVal -= 0.0025;
			}
			else{
				secondVal *= 0.442;
			}
			
			float X = v.vTexCoord.x;
			float Y = v.vTexCoord.y;
				
			if(vTime < 0.5)
			{
				Y -= firstVal;
			}
			else if(vTime >= 0.5 && vTime < 1.5)
			{
				float distance = secondVal - firstVal;
				
				//Because we doing a sine curve, we need to make vTime between -1.5 and 1.5
				//Move it to between 0-3
				float fTime = (vTime - 0.5) * 3.f;
				//Adjust to -1.5 to 1.5
				fTime -= 1.5f;
				fTime = sin(fTime);
				
				//Output is between -1 and 1 so we need to move it back to between 0 and 1
				fTime += 1.f;
				fTime /= 2.f;
				
				float yVal = firstVal + (distance * (fTime));
				
				Y -= yVal;
			}
			else{
				Y -= secondVal;
			}
			
			OutColor = tex2D( MapTexture, float2(X, Y));
			if(X < 0 || X > 1 || Y < 0 || Y > 1)
			{
				return float4(0,0,0,0);
			}
			
			return OutColor;
		}
	]]

	MainCode PixelShaderDown
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
					
		#ifdef ANIMATED
			OutColor = Animate(OutColor, v.vTexCoord, v.vAnimatedTexCoord, MaskTexture, AnimatedTexture, MaskTexture2, AnimatedTexture2);
		#endif

		#ifdef MASKING
			float4 MaskColor = tex2D( MaskingTexture, v.vTexCoord );
			OutColor.a *= MaskColor.a;
		#endif
			
			OutColor *= Color;

			float vTime = 0.9 - saturate( (Time - AnimationTime) * 16 );
			vTime *= vTime;
			vTime = 0.9*0.9 - vTime;
		    float4 MixColor = float4( 0.15, 0.15, 0.15, 0 ) * vTime;
		    OutColor.rgb -= ( 0.5 + OutColor.rgb ) * MixColor.rgb;

			return OutColor;
		}
	]]

	MainCode PixelShaderDisable
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
			
			float value = NextOffset.x;
			
			//Input is AB with A being the starting of the three frame and B being the end (1-3)
			float firstVal = floor(value/10.f);
			float secondVal = floor(value) - (firstVal*10.f);
			
			float vTime = Time - AnimationTime;
			
			firstVal -= 1;
			secondVal -= 1;
			
			if(firstVal == 2)
			{
				firstVal *= 0.442;
				firstVal -= 0.0025;
			}
			else{
				firstVal *= 0.442;
			}
			
			if(secondVal == 2)
			{
				secondVal *= 0.442;
				secondVal -= 0.0025;
			}
			else{
				secondVal *= 0.442;
			}
			
			float X = v.vTexCoord.x;
			float Y = v.vTexCoord.y;
				
			if(vTime < 0.5)
			{
				Y -= firstVal;
			}
			else if(vTime >= 0.5 && vTime < 1.5)
			{
				float distance = secondVal - firstVal;
				
				//Because we doing a sine curve, we need to make vTime between -1.5 and 1.5
				//Move it to between 0-3
				float fTime = (vTime - 0.5) * 3.f;
				//Adjust to -1.5 to 1.5
				fTime -= 1.5f;
				fTime = sin(fTime);
				
				//Output is between -1 and 1 so we need to move it back to between 0 and 1
				fTime += 1.f;
				fTime /= 2.f;
				
				float yVal = firstVal + (distance * (fTime));
				
				Y -= yVal;
			}
			else{
				Y -= secondVal;
			}
			
			OutColor = tex2D( MapTexture, float2(X, Y));
			if(X < 0 || X > 1 || Y < 0 || Y > 1)
			{
				return float4(0,0,0,0);
			}
			
			return OutColor;
		}	
	]]

	MainCode PixelShaderOver
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
				
		#ifdef ANIMATED
			OutColor = Animate(OutColor, v.vTexCoord, v.vAnimatedTexCoord, MaskTexture, AnimatedTexture, MaskTexture2, AnimatedTexture2);
		#endif

		#ifdef MASKING
			float4 MaskColor = tex2D( MaskingTexture, v.vTexCoord );
			OutColor.a *= MaskColor.a;
		#endif

			OutColor *= Color;
			
			float vTime = 0.9 - saturate( (Time - AnimationTime) * 4 );
			vTime *= vTime;
			vTime = 0.9*0.9 - vTime;
		    float4 MixColor = float4( 0.15, 0.15, 0.15, 0 ) * vTime;
		    OutColor.rgb += ( 0.5 + OutColor.rgb ) * MixColor.rgb;
			
			return OutColor;
		}
	]]
}


BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "src_alpha"
	DestBlend = "inv_src_alpha"
}


Effect Up
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderUp"
}

Effect Down
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderDown"
}

Effect Disable
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderDisable"
}

Effect Over
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderOver"
}


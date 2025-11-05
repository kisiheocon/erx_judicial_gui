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
			
			float value = NextOffset.x * 3.f;
			
			//Input is AB with A being the starting of the three frame and B being the end (1-3)
			float firstVal = floor(value/10.f);
			float secondVal = value - (firstVal*10.f);
			
			float skipVal = 0;
			if(firstVal == secondVal)
			{
				skipVal = 1;
			}
			
			//Move them between 0 and 2
			firstVal -= 1.f;
			secondVal -= 1.f;
			
			//Clamp values in case out of range
			if(firstVal < 0)
			{
				firstVal = 0;
			}
			else if(firstVal > 2)
			{
				firstVal = 2;
			}
			
			if(secondVal < 0)
			{
				secondVal = 0;
			}
			else if(secondVal > 2)
			{
				secondVal = 2;
			}
			
			float vTime = Time - AnimationTime;
			
			//Distance to travel
			float distance = secondVal - firstVal;
			
			//Zoom Out
			if(vTime < 0.5 && skipVal == 0)
			{
				float X = v.vTexCoord.x + (firstVal/3.f);
				float Y = v.vTexCoord.y;
				
				//Calculate midPoint
				float midPoint = ((firstVal * 2.f) + 1.f)/6.f;
				
				float scaleFactor = ((vTime * 2.f) * 0.1f) + 1.f;
				
				//Take distance from midpoint (scaling it around centre)
				X -= midPoint;
				Y -= 0.5f;
				
				//Shrink it
				X *= scaleFactor;
				Y *= scaleFactor;
				
				//Readjust
				X += midPoint;
				Y += 0.5f;
				
				if(X > ((firstVal + 1.f)/3.f) || X < (firstVal/3.f) || Y > 1 || Y < 0)
				{
					return float4(0,0,0,0);
				}
				
				OutColor = tex2D( MapTexture, float2(X, Y) );
			}
			//Slide Animation
			else if(vTime > 0.5f && vTime < 1.5f && skipVal == 0)
			{
				//Within the animation block
				
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
				
				yVal += v.vTexCoord.y;
				
				//Now we work out which frame it is, the 1s part of the yVal will tell us that (0 = first, 1 = second, 2 = third)
				float frameNumber = floor(yVal);
				
				//Take it off the Y val so it is between 0-1
				yVal -= frameNumber;
				
				float X = v.vTexCoord.x + (frameNumber/3.f);
				float Y = yVal;
				
				//This next bit is to scale it
				
				//Calculate midPoint
				float midPoint = ((frameNumber * 2.f) + 1.f)/6.f;
				
				
				//Take distance from midpoint (scaling it around centre)
				X -= midPoint;
				Y -= 0.5f;
				
				//Shrink it
				X *= 1.1f;
				Y *= 1.1f;
				
				//Readjust
				X += midPoint;
				Y += 0.5f;
				
				if(X > ((frameNumber + 1.f)/3.f) || X < (frameNumber/3.f) || Y > 1 || Y < 0)
				{
					return float4(0,0,0,0);
				}
				
				OutColor = tex2D( MapTexture, float2(X, Y) );
			}
			//Zoom in
			else if(vTime >= 1.5 && vTime < 2.0 && skipVal == 0)
			{
				float X = v.vTexCoord.x + (secondVal/3.f);
				float Y = v.vTexCoord.y;
				
				//Calculate midPoint
				float midPoint = ((secondVal * 2.f) + 1.f)/6.f;
				
				float scaleFactor = (0.1f - (((vTime-1.5f) * 2.f) * 0.1f)) + 1.f;
				
				//Take distance from midpoint (scaling it around centre)
				X -= midPoint;
				Y -= 0.5f;
				
				//Shrink it
				X *= scaleFactor;
				Y *= scaleFactor;
				
				//Readjust
				X += midPoint;
				Y += 0.5f;
				
				if(X > ((secondVal + 1.f)/3.f) || X < (secondVal/3.f) || Y > 1 || Y < 0)
				{
					return float4(0,0,0,0);
				}
				
				OutColor = tex2D( MapTexture, float2(X, Y) );
			}
			else{
				//Outside animation block just display the target version
				OutColor = tex2D( MapTexture, float2(v.vTexCoord.x + (secondVal/3.f), v.vTexCoord.y) );
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
			
			float value = NextOffset.x * 3.f;
			
			//Input is AB with A being the starting of the three frame and B being the end (1-3)
			float firstVal = floor(value/10.f);
			float secondVal = value - (firstVal*10.f);
			
			float skipVal = 0;
			if(firstVal == secondVal)
			{
				skipVal = 1;
			}
			
			//Move them between 0 and 2
			firstVal -= 1.f;
			secondVal -= 1.f;
			
			//Clamp values in case out of range
			if(firstVal < 0)
			{
				firstVal = 0;
			}
			else if(firstVal > 2)
			{
				firstVal = 2;
			}
			
			if(secondVal < 0)
			{
				secondVal = 0;
			}
			else if(secondVal > 2)
			{
				secondVal = 2;
			}
			
			float vTime = Time - AnimationTime;
			
			//Distance to travel
			float distance = secondVal - firstVal;
			
			//Zoom Out
			if(vTime < 0.5 && skipVal == 0)
			{
				float X = v.vTexCoord.x + (firstVal/3.f);
				float Y = v.vTexCoord.y;
				
				//Calculate midPoint
				float midPoint = ((firstVal * 2.f) + 1.f)/6.f;
				
				float scaleFactor = ((vTime * 2.f) * 0.1f) + 1.f;
				
				//Take distance from midpoint (scaling it around centre)
				X -= midPoint;
				Y -= 0.5f;
				
				//Shrink it
				X *= scaleFactor;
				Y *= scaleFactor;
				
				//Readjust
				X += midPoint;
				Y += 0.5f;
				
				if(X > ((firstVal + 1.f)/3.f) || X < (firstVal/3.f) || Y > 1 || Y < 0)
				{
					return float4(0,0,0,0);
				}
				
				OutColor = tex2D( MapTexture, float2(X, Y) );
			}
			//Slide Animation
			else if(vTime > 0.5f && vTime < 1.5f && skipVal == 0)
			{
				//Within the animation block
				
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
				
				yVal += v.vTexCoord.y;
				
				//Now we work out which frame it is, the 1s part of the yVal will tell us that (0 = first, 1 = second, 2 = third)
				float frameNumber = floor(yVal);
				
				//Take it off the Y val so it is between 0-1
				yVal -= frameNumber;
				
				float X = v.vTexCoord.x + (frameNumber/3.f);
				float Y = yVal;
				
				//This next bit is to scale it
				
				//Calculate midPoint
				float midPoint = ((frameNumber * 2.f) + 1.f)/6.f;
				
				
				//Take distance from midpoint (scaling it around centre)
				X -= midPoint;
				Y -= 0.5f;
				
				//Shrink it
				X *= 1.1f;
				Y *= 1.1f;
				
				//Readjust
				X += midPoint;
				Y += 0.5f;
				
				if(X > ((frameNumber + 1.f)/3.f) || X < (frameNumber/3.f) || Y > 1 || Y < 0)
				{
					return float4(0,0,0,0);
				}
				
				OutColor = tex2D( MapTexture, float2(X, Y) );
			}
			//Zoom in
			else if(vTime >= 1.5 && vTime < 2.0 && skipVal == 0)
			{
				float X = v.vTexCoord.x + (secondVal/3.f);
				float Y = v.vTexCoord.y;
				
				//Calculate midPoint
				float midPoint = ((secondVal * 2.f) + 1.f)/6.f;
				
				float scaleFactor = (0.1f - (((vTime-1.5f) * 2.f) * 0.1f)) + 1.f;
				
				//Take distance from midpoint (scaling it around centre)
				X -= midPoint;
				Y -= 0.5f;
				
				//Shrink it
				X *= scaleFactor;
				Y *= scaleFactor;
				
				//Readjust
				X += midPoint;
				Y += 0.5f;
				
				if(X > ((secondVal + 1.f)/3.f) || X < (secondVal/3.f) || Y > 1 || Y < 0)
				{
					return float4(0,0,0,0);
				}
				
				OutColor = tex2D( MapTexture, float2(X, Y) );
			}
			else{
				//Outside animation block just display the target version
				OutColor = tex2D( MapTexture, float2(v.vTexCoord.x + (secondVal/3.f), v.vTexCoord.y) );
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


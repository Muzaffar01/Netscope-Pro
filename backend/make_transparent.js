const Jimp = require('jimp');

async function processIcon() {
  try {
    const defaultImg = "C:\\Users\\MUZAFFAR\\.gemini\\antigravity\\brain\\3f52d00f-5c08-4206-a9e5-6aa56b1481ce\\netscope_app_icon_light_1775808850691.png";
    const image = await Jimp.read(defaultImg);

    // Target color to make transparent (pure white)
    const targetColor = { r: 255, g: 255, b: 255, a: 255 }; 
    const tolerance = 70; // High tolerance for antialiased white edges

    image.scan(0, 0, image.bitmap.width, image.bitmap.height, function (x, y, idx) {
      const red   = this.bitmap.data[idx + 0];
      const green = this.bitmap.data[idx + 1];
      const blue  = this.bitmap.data[idx + 2];
      const alpha = this.bitmap.data[idx + 3];

      // Calculate color distance from pure white
      const distance = Math.abs(red - targetColor.r) + 
                       Math.abs(green - targetColor.g) + 
                       Math.abs(blue - targetColor.b);

      if (distance <= tolerance) {
        // For pixels very close to white, make them fully transparent
        if (distance < 20) {
            this.bitmap.data[idx + 3] = 0; 
        } else {
            // For edge pixels, use partial transparency based on how close they are to white
            const opacity = Math.max(0, Math.min(255, Math.floor((distance / tolerance) * 255)));
            this.bitmap.data[idx + 3] = opacity;
        }
      }
    });

    // Save over the existing flutter asset icon
    await image.writeAsync("d:\\Projects\\AI\\v15\\assets\\app_icon.png");
    console.log("Successfully generated transparent app icon!");
  } catch (error) {
    console.error("Error processing icon:", error);
  }
}

processIcon();

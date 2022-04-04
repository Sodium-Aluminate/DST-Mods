import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.font.FontRenderContext;
import java.awt.geom.AffineTransform;
import java.awt.geom.Rectangle2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Map;

public class Main {
    public static void main(String[] args) throws IOException, FontFormatException {
        Map<String, String> env = System.getenv();
        int pngSize = Integer.parseInt(env.getOrDefault("PNG_SIZE", "32"));
        String fontPath = env.getOrDefault("FONT_PATH", "/tmp/SourceHanSansCN-Normal.otf");
        String output_dir = env.getOrDefault("OUTPUT_DIR", "/tmp/output-png/");
        int outputColor = Integer.parseInt(env.getOrDefault("OUTPUT_COLOR", "0"), 16);
        new File(output_dir).mkdirs();

        boolean testMode = env.getOrDefault("TEST_MODE", "false").equals("true");

        Font font;
        try (FileInputStream fileInputStream = new FileInputStream(new File(fontPath))) {
            font = Font.createFont(Font.TRUETYPE_FONT, fileInputStream)
                    .deriveFont(Font.PLAIN, pngSize);
        }

        test:
        {
            BufferedImage bufferedImage = new BufferedImage(pngSize, pngSize, BufferedImage.TYPE_INT_ARGB);
            Graphics2D graphics2D = bufferedImage.createGraphics();
            graphics2D.setFont(font);
            graphics2D.setColor(new Color(outputColor));

            if (!testMode) break test;
            char testTarget = '草';
            graphics2D.drawString("" + testTarget, 0, 28);
            ImageIO.write(bufferedImage, "PNG", new File(output_dir + "/u" +
                    (Integer.toHexString(testTarget))));
        }
        FontRenderContext fontRenderContext = new FontRenderContext(new AffineTransform(), true, true);
        if (!testMode) {
            for (char i = 0x4e00; i <= 0x9fff; i++) {
                System.out.print(""+i + "\t");
                Rectangle2D stringBounds = font.getStringBounds("" + i, fontRenderContext);
                assert stringBounds.getWidth()==32.00006103515625d;
                assert stringBounds.getHeight()==46.33609390258789;
                System.out.println();
                BufferedImage bufferedImage = new BufferedImage(pngSize, pngSize, BufferedImage.TYPE_INT_ARGB);
                Graphics2D graphics2D = bufferedImage.createGraphics();
                graphics2D.setFont(font);
                graphics2D.setColor(new Color(outputColor));

                graphics2D.drawString("" + i, 0, 28);
                ImageIO.write(bufferedImage, "PNG", new File(output_dir + "/u" +
                        (Integer.toHexString(i)) + ".png"));
            }
        }
    }
}
settings.outformat = "svg";

unitsize(1cm);

// Colors.
pen julia_green = rgb("389826");
pen julia_red = rgb("CB3C33");
pen julia_lila = rgb("9558B2");

// Draw the Julia logo.
void drawcircle(real rotangle, pen color) {
    path item = rotate(rotangle) * shift(0, 1.35) * unitcircle;
    filldraw(item, fillpen = color, drawpen = color);
}

real[] angles = {0, degrees(2 * pi / 3), degrees(-2 * pi / 3)};
pen[] colors = {julia_green, julia_red, julia_lila};

for (int k = 0; k < 3; ++k) {
    drawcircle(angles[k], colors[k]);
}

// Draw the checkmark.
texpreamble("\usepackage{amssymb}");
string checkmark = "\checkmark";
label(scale(7.5) * shift(1.5, 2.5) * checkmark,
      position = rotate(angles[1]) * shift(0, 1.35) * (0, 0));

extends SceneTree

# Original, deterministic periodic noise data for the material shaders.
# Bake once; avoid computing many trigonometric hashes for every screen pixel.
func _initialize() -> void:
    var image := Image.create(128, 128, false, Image.FORMAT_RGB8)
    var noise := FastNoiseLite.new()
    noise.seed = 71029
    noise.frequency = 0.045
    noise.fractal_octaves = 3
    for x in range(128):
        for y in range(128):
            var u := x / 128.0
            var v := y / 128.0
            var first := lerpf(noise.get_noise_2d(x, y), noise.get_noise_2d(x - 128, y), u)
            var second := lerpf(noise.get_noise_2d(x, y - 128), noise.get_noise_2d(x - 128, y - 128), u)
            var value := lerpf(first, second, v) * 0.5 + 0.5
            var medium := noise.get_noise_2d(x * 2.0, y * 2.0) * 0.5 + 0.5
            var grain := noise.get_noise_2d(x * 11.0, y * 11.0) * 0.5 + 0.5
            image.set_pixel(x, y, Color(value, medium, grain))
    var error := image.save_png("res://assets/materials/detail_noise.png")
    print("MATERIAL DATA: ", error_string(error))
    quit(0 if error == OK else 1)

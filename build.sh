#!/bin/bash
set -e

mkdir -p build

export EM_CACHE="${EM_CACHE:-$PWD/build/emcache}"
mkdir -p "$EM_CACHE"

gcc tools/packer.c -O2 -o tools/packer
./tools/packer contents > generated/contents_data.h

# 1. Static Assets Hashing
PFP_SRC="public/pfp.avif"
PFP_HASH=$(shasum -a 256 "$PFP_SRC" | cut -c 1-8)
PFP_DIST="public/pfp.$PFP_HASH.avif"

FONT_REGULAR_SRC="public/lmroman10-regular.otf"
FONT_BOLD_SRC="public/lmroman10-bold.otf"
FONT_ITALIC_SRC="public/lmroman10-italic.otf"
FONT_BOLDITALIC_SRC="public/lmroman10-bolditalic.otf"

FONT_REGULAR_HASH=$(shasum -a 256 "$FONT_REGULAR_SRC" | cut -c 1-8)
FONT_BOLD_HASH=$(shasum -a 256 "$FONT_BOLD_SRC" | cut -c 1-8)
FONT_ITALIC_HASH=$(shasum -a 256 "$FONT_ITALIC_SRC" | cut -c 1-8)
FONT_BOLDITALIC_HASH=$(shasum -a 256 "$FONT_BOLDITALIC_SRC" | cut -c 1-8)

FONT_REGULAR_DIST="public/lmroman10-regular.$FONT_REGULAR_HASH.otf"
FONT_BOLD_DIST="public/lmroman10-bold.$FONT_BOLD_HASH.otf"
FONT_ITALIC_DIST="public/lmroman10-italic.$FONT_ITALIC_HASH.otf"
FONT_BOLDITALIC_DIST="public/lmroman10-bolditalic.$FONT_BOLDITALIC_HASH.otf"

# Cleanup old versions
rm -f public/pfp.*.avif
rm -f public/lmroman10-regular.*.otf
rm -f public/lmroman10-bold.*.otf
rm -f public/lmroman10-italic.*.otf
rm -f public/lmroman10-bolditalic.*.otf
cp "$PFP_SRC" "$PFP_DIST"
cp "$FONT_REGULAR_SRC" "$FONT_REGULAR_DIST"
cp "$FONT_BOLD_SRC" "$FONT_BOLD_DIST"
cp "$FONT_ITALIC_SRC" "$FONT_ITALIC_DIST"
cp "$FONT_BOLDITALIC_SRC" "$FONT_BOLDITALIC_DIST"
echo "#define ASSET_PFP \"$PFP_DIST\"" > generated/assets.h
echo "#define ASSET_FONT \"$FONT_REGULAR_DIST\"" >> generated/assets.h

# 2. Compilation
echo "Compiling WASM..."
emcc \
src/*.c \
-Oz -flto -Iinclude -Igenerated -s WASM=1 -s ASSERTIONS=0 -s SAFE_HEAP=0 -s STACK_OVERFLOW_CHECK=0 \
-s FILESYSTEM=0 -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
-s EXPORTED_FUNCTIONS='["_main","_ui_toggle_theme","_switch_page","_render_markdown","_handle_route","_handle_current_route","_draw_frame"]' \
-s EXPORTED_RUNTIME_METHODS='["UTF8ToString","ccall","cwrap"]' \
-o build/app.js

# Generate compile_commands.json
echo "[" > compile_commands.json
FILES=(src/*.c)
for i in "${!FILES[@]}"; do
    file="${FILES[$i]}"
    emcc "$file" -Iinclude -Igenerated -DEMSCRIPTEN -MJ "$file.json" -c -o "build/$(basename "$file" .c).o"
    # Remove any trailing comma and newline to control the structure manually
    cat "$file.json" >> compile_commands.json
    rm "$file.json"
done
# Remove last comma if exists and close array
sed -i '' '$ s/,$//' compile_commands.json
echo "]" >> compile_commands.json

# 3. Post-processing and JS/WASM Hashing
wasm-opt -Oz --enable-bulk-memory --enable-nontrapping-float-to-int build/app.wasm -o build/app.wasm || echo "wasm-opt skipped"
node -e "const fs=require('fs'); WebAssembly.compile(fs.readFileSync('build/app.wasm')).catch(e=>{ console.error(e); process.exit(1); })"
terser build/app.js -c -m -o build/app.js || echo "terser skipped"

JS_HASH=$(shasum -a 256 build/app.js | cut -c 1-8)
WASM_HASH=$(shasum -a 256 build/app.wasm | cut -c 1-8)

# Cleanup old builds before renaming
rm -f build/app.*.js build/app.*.wasm build/app.*.br

mv build/app.wasm "build/app.$WASM_HASH.wasm"
mv build/app.js "build/app.$JS_HASH.js"

# Patch JS to point to new .wasm
sed -i '' "s/app.wasm/app.$WASM_HASH.wasm/g" "build/app.$JS_HASH.js"

# 4. Generate final index.html
sed "s|{{PFP}}|$PFP_DIST|g; s|{{FONT_REGULAR}}|$FONT_REGULAR_DIST|g; s|{{FONT_BOLD}}|$FONT_BOLD_DIST|g; s|{{FONT_ITALIC}}|$FONT_ITALIC_DIST|g; s|{{FONT_BOLDITALIC}}|$FONT_BOLDITALIC_DIST|g; s|{{JS}}|build/app.$JS_HASH.js|g" index.template.html > index.html

# 5. Compression (optional .br files)
brotli -f -Z "build/app.$JS_HASH.js" || echo "brotli skipped"
brotli -f -Z "build/app.$WASM_HASH.wasm" || echo "brotli skipped"

echo "Build successful: index.html updated."

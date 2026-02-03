#!/bin/bash
# Normalize all bufo stickers to a consistent size for iMessage
# - Trims transparent borders
# - Resizes to fit within 408x408 (iMessage "medium" sticker size)
# - Centers on a transparent 408x408 canvas

STICKER_DIR="BufoStickers/MessagesExtension/Stickers"
TARGET_SIZE=408
PROCESSED=0
FAILED=0
TOTAL=$(ls "$STICKER_DIR"/*.png "$STICKER_DIR"/*.gif 2>/dev/null | wc -l | tr -d ' ')

echo "Normalizing $TOTAL stickers to ${TARGET_SIZE}x${TARGET_SIZE}..."

# Process PNGs
for img in "$STICKER_DIR"/*.png; do
    [ -f "$img" ] || continue
    
    magick "$img" \
        -trim +repage \
        -resize "${TARGET_SIZE}x${TARGET_SIZE}>" \
        -background none \
        -gravity center \
        -extent "${TARGET_SIZE}x${TARGET_SIZE}" \
        "$img" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        ((PROCESSED++))
    else
        ((FAILED++))
        echo "  FAILED: $(basename "$img")"
    fi
    
    if [ $((PROCESSED % 100)) -eq 0 ] && [ $PROCESSED -gt 0 ]; then
        echo "  Processed $PROCESSED / $TOTAL..."
    fi
done

# Process GIFs (need coalesce/optimize for animated frames)
for img in "$STICKER_DIR"/*.gif; do
    [ -f "$img" ] || continue
    
    magick "$img" \
        -coalesce \
        -trim +repage \
        -resize "${TARGET_SIZE}x${TARGET_SIZE}>" \
        -background none \
        -gravity center \
        -extent "${TARGET_SIZE}x${TARGET_SIZE}" \
        -layers Optimize \
        "$img" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        ((PROCESSED++))
    else
        ((FAILED++))
        echo "  FAILED: $(basename "$img")"
    fi
    
    if [ $((PROCESSED % 100)) -eq 0 ] && [ $PROCESSED -gt 0 ]; then
        echo "  Processed $PROCESSED / $TOTAL..."
    fi
done

echo ""
echo "Done! Processed: $PROCESSED, Failed: $FAILED"

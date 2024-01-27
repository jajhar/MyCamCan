#ifndef RedSoxApp_CoreGraphicsRootines_h
#define RedSoxApp_CoreGraphicsRootines_h

NS_INLINE CGFloat CGLinePixelWidth(CGFloat widthPixels, CGFloat scale) {
    return widthPixels / scale;
}

NS_INLINE CGRect CGRectOffsetForCGLineDrawing(CGRect rect, CGFloat lineWidthPx) {
    CGFloat halfLineWidthPx = lineWidthPx / (CGFloat)2;
    rect.origin.x += halfLineWidthPx;
    rect.origin.y += halfLineWidthPx;
    rect.size.width -= halfLineWidthPx + halfLineWidthPx;
    rect.size.height -= halfLineWidthPx + halfLineWidthPx;
    return rect;
}

NS_INLINE CGRect CGRectOffsetForCGLineDrawingZeroOrigin(CGRect rect, CGFloat lineWidthPx) {
    CGFloat halfLineWidthPx = lineWidthPx / (CGFloat)2;
    rect.origin.x = halfLineWidthPx;
    rect.origin.y = halfLineWidthPx;
    rect.size.width -= halfLineWidthPx + halfLineWidthPx;
    rect.size.height -= halfLineWidthPx + halfLineWidthPx;
    return rect;
}

#endif

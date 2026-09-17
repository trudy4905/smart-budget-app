$files = @("flutter_app/lib/main.dart", "flutter_app/lib/state.dart")
$replacements = @{
    "Colors.white" = "Color(0xFF0F172A)"
    "Color(0xFF0F172A)" = "Color(0xFFF1F5F9)"
    "Color(0xFF1E293B)" = "Color(0xFFFFFFFF)"
    "Color(0xFF334155)" = "Color(0xFFE2E8F0)"
    "Color(0xFF475569)" = "Color(0xFFF8FAFC)"
    "Color(0xFF64748B)" = "Color(0xFF94A3B8)"
    "Color(0xFF94A3B8)" = "Color(0xFF64748B)"
    "Color(0xFF6366F1)" = "Color(0xFF4F46E5)"
    "Color(0xFFF43F5E)" = "Color(0xFFE11D48)"
    "Color(0xFF10B981)" = "Color(0xFF059669)"
    "Color(0xFF3B82F6)" = "Color(0xFF2563EB)"
    "Color(0xFF8B5CF6)" = "Color(0xFF7C3AED)"
    "Color(0xFFEF4444)" = "Color(0xFFDC2626)"
    "Color(0xFFA855F7)" = "Color(0xFF9333EA)"
}

$tokens = @{}
$i = 100
foreach ($k in $replacements.Keys) {
    $tokens[$k] = "__SAFE_TOKEN_$i"
    $i++
}

foreach ($file in $files) {
    $text = [IO.File]::ReadAllText($file)
    foreach ($k in $replacements.Keys) {
        $escaped = [regex]::Escape($k)
        if ($k -eq "Colors.white") {
            $escaped = "Colors\.white(?!\d)"
        }
        $text = [regex]::Replace($text, $escaped, $tokens[$k])
    }
    foreach ($k in $replacements.Keys) {
        $text = $text.Replace($tokens[$k], $replacements[$k])
    }
    [IO.File]::WriteAllText($file, $text)
}

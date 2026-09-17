import os

def extract_block(text, start_index):
    brace_start = text.find('{', start_index)
    if brace_start == -1: return None
    count = 1
    idx = brace_start + 1
    while count > 0 and idx < len(text):
        if text[idx] == '{': count += 1
        elif text[idx] == '}': count -= 1
        idx += 1
    return idx

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    build_start = content.rfind('Widget build(BuildContext context)')
    build_end_idx = extract_block(content, build_start)
    
    # get the lines around build_end_idx
    start_excerpt = max(0, build_end_idx - 150)
    end_excerpt = min(len(content), build_end_idx + 100)
    print(content[start_excerpt:end_excerpt])

if __name__ == '__main__':
    main()

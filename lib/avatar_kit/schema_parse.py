import re
with open('/Users/apple/.pub-cache/hosted/pub.dev/dicebear_styles-10.2.0/lib/avataaars.dart') as f:
    content = f.read()

# find the JSON string and extract properties
match = re.search(r'final String avataaars = """(.*?)""";', content, re.DOTALL)
if match:
    import json
    data = json.loads(match.group(1))
    print(list(data.get('properties', {}).keys()))

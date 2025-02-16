#!/usr/bin/env python3
import sys
import re
import json

class CodeAnalyzer:
    def __init__(self):
        self.patterns = {
            'security_issues': [
                r'password\s*=\s*[\'"][^\'"]+[\'"]',
                r'secret\s*=\s*[\'"][^\'"]+[\'"]',
                r'api_key\s*=\s*[\'"][^\'"]+[\'"]'
            ],
            'performance_issues': [
                r'while\s*True:',Docker Desktop - WSL distro terminated abr
                r'\.sleep\(',
                r'select\s+\*\s+from'
            ],
            'best_practices': [
                r'print\(',
                r'catch\s*Exception:',
                r'exec\('
            ]
        }

    def analyze_file(self, content):
        results = {
            'security_issues': [],
            'performance_issues': [],
            'best_practices': []
        }

        lines = content.split('\n')
        for i, line in enumerate(lines, 1):
            for category, patterns in self.patterns.items():
                for pattern in patterns:
                    if re.search(pattern, line, re.IGNORECASE):
                        results[category].append({
                            'line': i,
                            'content': line.strip(),
                            'issue': pattern
                        })

        return results

    def format_results(self, results):
        output = {
            'summary': {
                'security_issues': len(results['security_issues']),
                'performance_issues': len(results['performance_issues']),
                'best_practices': len(results['best_practices'])
            },
            'details': results
        }
        return json.dumps(output, indent=2)

def main():
    if len(sys.argv) != 2:
        print("Usage: ./code-analyzer.py <file_path>")
        sys.exit(1)

    analyzer = CodeAnalyzer()
    try:
        with open(sys.argv[1], 'r') as file:
            content = file.read()
            results = analyzer.analyze_file(content)
            print(analyzer.format_results(results))
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
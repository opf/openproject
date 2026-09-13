import os
import sys

def main():
    root_dir = sys.argv[1]
    print(f"Scanning {root_dir}")
    for c, d, files in os.walk(root_dir):
        for f in files:
            if f.endswith('.py') or f.endswith('.json'):
                p = os.path.join(c, f)
                with open(p, 'rb') as x:
                    cont = x.read()
                if b'\x00' in cont:
                    print('Fixing UTF-16 in', p)
                    try:
                        text = cont.decode('utf-16le')
                    except Exception:
                        try:
                            text = cont.decode('utf-16be')
                        except Exception as e:
                            print("Could not decode", p)
                            continue
                    with open(p, 'wb') as x:
                        x.write(text.encode('utf-8'))
                        
    print("Done scanning.")

if __name__ == "__main__":
    main()

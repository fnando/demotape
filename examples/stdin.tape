Type """
echo "Type 'echo \"it works with stdin too\"'\nEnter\nSleep 5" | \
exe/demotape run --overwrite --output-path examples/stdin.mp4
"""
Enter
WaitUntil /Finished in/
Sleep 3s

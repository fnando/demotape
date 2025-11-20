Type """
echo "Type 'echo \"it works with stdin too\"'\nEnter\nSleep 5" | \
exe/demotape run --overwrite --output-path examples/stdin_output.mp4
"""
Enter
WaitUntil /Finished in/
Sleep 3s

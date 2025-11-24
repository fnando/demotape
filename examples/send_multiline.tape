Sleep 1s
Send """
echo Hello!
echo Goodbye!
"""
WaitUntil /^Goodbye/

Sleep 3s

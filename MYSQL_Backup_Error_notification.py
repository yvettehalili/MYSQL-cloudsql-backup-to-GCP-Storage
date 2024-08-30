import subprocess
import sys

def send_email(subject, body, to="yvette.halili@telusinternational.com", from_email="backup@yourdomain.com"):
    ssmtp_command = "/usr/sbin/ssmtp"
    
    email_content = f"""To: {to}
From: {from_email}
MIME-Version: 1.0
Content-Type: text/html; charset=utf-8
Subject: {subject}

Hi DBA Team,<br /><br />
Oopsie daisy! We encountered a bit of a hiccup during the backup process:<br /><br />
{body}<br /><br />
But don't worry, we're on it!<br />
Kind Regards,<br />
Your Backup System
"""
    
    try:
        process = subprocess.Popen(ssmtp_command, stdin=subprocess.PIPE, shell=True)
        process.stdin.write(email_content.encode('utf-8'))
        process.stdin.close()
        process.wait()
    except Exception as e:
        print(f"Failed to send email: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: send_email.py <subject> <body>")
        sys.exit(1)

    subject = sys.argv[1]
    body = sys.argv[2]
    send_email(subject, body)

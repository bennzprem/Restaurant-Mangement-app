"""
Email utility functions for the ByteEat application.
"""
import os
from flask import current_app
from flask_mail import Message

def _is_mail_configured() -> bool:
    """Check if mail is properly configured."""
    return bool(current_app.config.get('MAIL_USERNAME') and current_app.config.get('MAIL_PASSWORD'))

def _send_password_reset_email(recipient_email: str, token: str, mail, frontend_base_url: str) -> tuple[bool, str]:
    """Sends password reset email. Returns (sent, link_used).

    Args:
        recipient_email: Email address to send reset link to
        token: Reset token for the password reset
        mail: Flask-Mail instance
        frontend_base_url: Base URL for the frontend application

    Returns:
        tuple: (sent: bool, link_used: str)
            sent: True if mail sent without exception
            link_used: The reset link included in the email (for logging/debug)
    """
    reset_link = f"{frontend_base_url.rstrip('/')}/reset-password.html?token={token}"
    if not _is_mail_configured():
        return False, reset_link
    try:
        msg = Message('Password Reset Request', recipients=[recipient_email])
        msg.body = (
            "Hello,\n\nPlease use the following link to reset your password:\n"
            f"{reset_link}\n\nThis link will expire in one hour."
        )
        mail.send(msg)
        return True, reset_link
    except Exception as e:
        return False, reset_link

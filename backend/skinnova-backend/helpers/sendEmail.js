const nodemailer = require("nodemailer");

let _transporter = null;

function getTransporter() {
  if (_transporter) return _transporter;

  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    return null;
  }

  _transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  return _transporter;
}

/**
 * Send a plain or HTML email.
 *
 * @param {Object} opts
 * @param {string} opts.to
 * @param {string} opts.subject
 * @param {string} opts.html
 */
async function sendEmail({ to, subject, html }) {
  const transporter = getTransporter();
  if (!transporter) {
    console.warn("[Email] EMAIL_USER / EMAIL_PASS not configured — email not sent");
    return;
  }

  await transporter.sendMail({
    from: `"Skinova" <${process.env.EMAIL_USER}>`,
    to,
    subject,
    html,
  });
}

/**
 * Pre-built OTP email template.
 */
function otpEmailHtml(otp) {
  return `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#F7F4F3;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F7F4F3;padding:40px 0;">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0"
        style="background:#ffffff;border-radius:20px;overflow:hidden;
               box-shadow:0 4px 24px rgba(91,35,51,0.10);">
        <!-- Header -->
        <tr>
          <td style="background:linear-gradient(135deg,#5B2333,#7A3346);
                     padding:32px 40px;text-align:center;">
            <p style="margin:0;font-size:28px;color:#fff;font-weight:700;
                      letter-spacing:1px;">✦ Skinova</p>
            <p style="margin:8px 0 0;font-size:14px;color:rgba(255,255,255,0.80);">
              Your personal skincare companion
            </p>
          </td>
        </tr>
        <!-- Body -->
        <tr>
          <td style="padding:40px 40px 32px;">
            <h2 style="margin:0 0 12px;font-size:22px;color:#202124;font-weight:700;">
              Reset your password
            </h2>
            <p style="margin:0 0 24px;font-size:14.5px;color:#6B6B6B;line-height:1.6;">
              We received a request to reset your Skinova password.
              Use the code below — it expires in <strong>15 minutes</strong>.
            </p>
            <!-- OTP box -->
            <div style="background:#FDF2F4;border:1.5px solid #F0D0D6;
                        border-radius:14px;padding:20px 0;text-align:center;
                        margin-bottom:24px;">
              <p style="margin:0;font-size:36px;font-weight:800;
                        letter-spacing:10px;color:#5B2333;">${otp}</p>
            </div>
            <p style="margin:0 0 24px;font-size:13.5px;color:#6B6B6B;line-height:1.6;">
              If you didn't request this, you can safely ignore this email.
              Your password will not be changed.
            </p>
            <hr style="border:none;border-top:1px solid #EEECEC;margin:0 0 24px;">
            <p style="margin:0;font-size:12px;color:#AAAAAA;text-align:center;">
              © ${new Date().getFullYear()} Skinova. All rights reserved.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

module.exports = { sendEmail, otpEmailHtml };

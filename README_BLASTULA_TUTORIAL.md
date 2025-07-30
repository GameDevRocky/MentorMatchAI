# Blastula Email Tutorial for Students

## 📧 What You'll Learn

This tutorial teaches you how to design and send beautiful emails using the `blastula` package in R. You'll learn:

1. **Email Design Principles** - How to create responsive, professional email layouts
2. **HTML & CSS for Emails** - Best practices for email client compatibility
3. **Dynamic Content** - How to personalize emails with user data
4. **Blastula Package** - How to use blastula for sending emails
5. **Testing & Debugging** - How to test your emails before sending

## 🚀 Getting Started

### Option 1: Use Existing Credentials (Recommended for Students)

If your instructor has provided the credential files, you can use them directly:

```r
# Install required packages
install.packages("blastula")
install.packages("glue")

# Run the student setup script
source("student_email_setup.R")

# Load the main tutorial
source("blastula_email_tutorial.R")

# Test your email setup
test_email_setup()
```

### Option 2: Set Up Your Own Credentials

If you want to use your own email account:

```r
# Install the required packages
install.packages("blastula")
install.packages("glue")

# Load the packages
library(blastula)
library(glue)

# Load the tutorial
source("blastula_email_tutorial.R")
```

## 📚 What's Included

### 1. **Simple Welcome Email** (`create_simple_email()`)
- Professional header with branding
- Personalized greeting
- Feature highlights box
- Call-to-action button
- Mobile-responsive design

### 2. **Newsletter with Dynamic Content** (`create_newsletter_email()`)
- Gradient header design
- Dynamic mentor cards
- Personalized content using `glue()`
- Professional styling

### 3. **Email Sending Function** (`send_email_with_blastula()`)
- Test mode for previewing emails
- Real email sending with SMTP
- Error handling and user feedback

### 4. **Student Practice Function** (`student_practice_email()`)
- Customizable template for students
- Easy-to-modify design
- Personal message integration

## 🎯 How to Use

### Example 1: Create a Simple Welcome Email

```r
# Create email content
email_html <- create_simple_email("Sarah", "Data Science")

# Send email (in test mode)
send_email_with_blastula(
  to_email = "sarah@example.com",
  subject = "Welcome to MentorMatchAI! 🎉",
  html_content = email_html,
  test_mode = TRUE  # Set to FALSE for real sending
)
```

### Example 2: Create a Newsletter with Mentor Matches

```r
# Sample mentor data
mentor_matches <- list(
  list(
    name = "Dr. Sarah Chen",
    title = "Senior Data Scientist",
    expertise = "Machine Learning, Python, R",
    match_score = 95,
    rating = "4.9",
    reviews = "127"
  )
)

# Create newsletter content
email_html <- create_newsletter_email("John", mentor_matches)

# Send email
send_email_with_blastula(
  to_email = "john@example.com",
  subject = "🎯 Your Perfect Mentor Matches Are Here!",
  html_content = email_html,
  test_mode = TRUE
)
```

### Example 3: Practice Creating Your Own Email

```r
# Create a custom email
custom_email <- student_practice_email(
  student_name = "Alex",
  field_of_study = "Web Development",
  personal_message = "I'm excited to start my coding journey!"
)

# Send the custom email
send_email_with_blastula(
  to_email = "alex@example.com",
  subject = "Welcome to Our Platform!",
  html_content = custom_email,
  test_mode = TRUE
)
```

## ⚙️ Configuration for Real Email Sending

### Using Existing Credentials (Recommended)

If your instructor has provided the credential files (`gmail_creds` or `gmail_credss`), you can use them directly:

```r
# The student setup script will automatically configure everything
source("student_email_setup.R")
```

This will:
- Load the existing credentials
- Configure the email settings automatically
- Allow you to send real emails immediately

### Setting Up Your Own Credentials

If you want to use your own email account:

```r
# Update these settings in the tutorial file
EMAIL_CONFIG <- list(
  from_email = "your-email@gmail.com",  # Your email
  smtp_host = "smtp.gmail.com",
  smtp_port = 587,
  smtp_username = "your-email@gmail.com",  # Your email
  smtp_password = "your-app-password"      # Your app password
)
```

### Gmail Setup Instructions:

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate an App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a password for "Mail"
3. **Use the app password** in the `smtp_password` field

## 💡 Email Design Tips

### Best Practices:
1. **Mobile-First Design** - Keep emails under 600px width
2. **Inline CSS** - Use inline styles for email client compatibility
3. **Clear CTAs** - Make call-to-action buttons prominent
4. **Professional Colors** - Use consistent brand colors
5. **Unsubscribe Link** - Always include an unsubscribe option

### Technical Tips:
1. **Use `glue()`** for dynamic content insertion
2. **Test in Multiple Clients** - Gmail, Outlook, Apple Mail
3. **Handle Errors Gracefully** - Always include error handling
4. **Preview Before Sending** - Use test mode to preview emails

## 🔧 Troubleshooting

### Common Issues:

1. **Package Not Found**
   ```r
   install.packages("blastula")
   install.packages("glue")
   ```

2. **SMTP Connection Failed**
   - Check your email credentials
   - Ensure 2FA is enabled and app password is correct
   - Verify SMTP settings

3. **Email Not Rendering Properly**
   - Use inline CSS instead of external stylesheets
   - Test in different email clients
   - Keep HTML structure simple

## 📖 Next Steps

1. **Customize Templates** - Modify the email designs to match your brand
2. **Add More Dynamic Content** - Integrate with your database
3. **Create Email Campaigns** - Build automated email workflows
4. **A/B Testing** - Test different email designs and content
5. **Analytics** - Track email open rates and click-through rates

## 🎓 Learning Resources

- [Blastula Documentation](https://rich-iannone.github.io/blastula/)
- [Email HTML Best Practices](https://www.emailonacid.com/blog/)
- [Responsive Email Design](https://www.litmus.com/blog/)

## 📞 Support

If you have questions or need help:
- Check the code comments in the tutorial file
- Review the email design tips in the tutorial
- Test your emails in different email clients
- Use the test mode to preview before sending

---

**Happy Email Designing! 🎉** 
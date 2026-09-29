# ATN Submission Process

> This reference file is loaded on demand from ../SKILL.md for detailed ATN submission documentation.

## Pre-Submission Checklist

- [ ] Extension ID in `browser_specific_settings.gecko.id`
- [ ] Works with Thunderbird 128+
- [ ] All permissions are necessary
- [ ] Privacy policy included (if collecting data)
- [ ] No obfuscated code
- [ ] Source code available (if using build tools)
- [ ] Icons: 32x32 and 64x64 minimum
- [ ] Screenshots for listed extensions
- [ ] Clear description

## Submission Steps

1. **Build extension:**
   ```bash
   zip -r extension.zip manifest.json background.js icons/ popup.html
   ```

2. **Create developer account:**
   - Visit https://addons.thunderbird.net/developers/
   - Sign up and complete profile

3. **Submit:**
   - Go to Developer Hub → "Submit a New Add-on"
   - Upload `.zip` or `.xpi` file
   - Choose distribution: Listed (public) or Unlisted (direct)

4. **Fill listing:**
   - Name, description, categories
   - Screenshots, icons
   - Privacy policy (inline, not external link)
   - Support email/URL

5. **Review process:**
   - Automated validation: immediate
   - Manual review: 1-7 days for listed extensions
   - Respond to reviewer comments within 10 days

## Review Criteria

- Extension works with supported Thunderbird versions
- Uses only necessary permissions
- No remote code execution
- Uses HTTPS for sensitive data
- Clear privacy policy disclosure
- No Experiment API when built-in API exists
- No hidden functionality

## Privacy Policy Requirements

Must include (inline, not external):

```markdown
# Privacy Policy for [Add-on Name]

## Data Collection
[Specific description of what data is collected]

## Purpose
[Why data is collected]

## Storage
[How and where data is stored]

## Sharing
[Whether data is shared with third parties]

## User Control
[How users can delete their data]
```

## Common Rejection Reasons

| Reason | Solution |
|--------|----------|
| Doesn't work with supported versions | Test on Thunderbird 128+ |
| Uses Experiment when built-in API exists | Use MailExtension API |
| No response to reviewer comments | Check email, respond within 10 days |
| Unclear privacy policy | Be specific about data collection |
| Excessive permissions | Remove unused permissions |
| Missing source code | Provide if using minification |
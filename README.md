# MentorMatchAI Workshop Platform

A comprehensive workshop platform for learning AI, Frontend, and Backend development through building a mentorship matching system.

## Overview

This platform provides:
- Interactive learning tracks for Frontend, Backend, and AI Development
- Project-based learning with real-world applications
- Comprehensive workshop materials and guides
- Ticket-based task management system

## Project Structure

```
MentorMatchAI/
├── Frontend
│   ├── Byte_Learning_Platform.html  # Landing page
│   ├── courses.html                 # Course selection
│   ├── lessons.html                # Lesson content
│   └── dashboard-*.html            # Track-specific dashboards
├── Backend
│   ├── app.R                       # Main R Shiny application
│   ├── database_setup.R            # Database configuration
│   └── mentor_recommender.R        # AI matching system
└── Resources
    └── MENTORMATCH_WORKSHOP_GUIDE.txt  # Comprehensive guide
```

## Local Development

1. Clone the repository:
```bash
git clone https://github.com/[username]/MentorMatchAI.git
cd MentorMatchAI
```

2. Install R and required packages:
```R
install.packages(c("shiny", "DBI", "RSQLite", "text2vec"))
```

3. Start the R Shiny application:
```R
source("start_enhanced.R")
```

## Deployment

The frontend is deployed using GitHub Pages. The backend requires an R Shiny server.

### GitHub Pages Setup

1. Push to GitHub:
```bash
git remote add origin https://github.com/[username]/MentorMatchAI.git
git branch -M main
git push -u origin main
```

2. Enable GitHub Pages:
- Go to repository Settings > Pages
- Select 'main' branch
- Set root directory as source
- Save changes

The site will be available at: https://[username].github.io/MentorMatchAI/

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to the branch
5. Open a Pull Request

## License

MIT License - See LICENSE file for details 
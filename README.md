# CAPE Escalation Analysis System

[![R Version](https://img.shields.io/badge/R-%3E%3D%204.3.0-blue)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-1.7.0-green)](https://shiny.rstudio.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

## Overview

The CAPE Escalation Analysis System provides DoD cost estimators with a comprehensive, CAPE-compliant tool for generating custom inflation indices.

## Quick Start

### Installation

```r
# Install from GitHub
devtools::install_github("your-org/cape-escalation")
# Or run locally
source("setup.R")
run_setup()
```

### Launch Application

```r
library(capeEscalation)
launch_cape_app()
```

## Features
- Automated PPI Index Retrieval from FRED API
- Advanced Forecasting with time series and ML
- Outlay Profile Integration for weighted escalation
- CAPE Compliance validation
- Comprehensive Export with documentation

## Documentation
- [User Guide](docs/user_guide.md)
- [CAPE Methodology](docs/cape_methodology.md)
- [API Reference](docs/api_reference.md)
- [Best Practices](docs/best_practices.md)

## Support
- Issues: [GitHub Issues](https://github.com/your-org/cape-escalation/issues)
- Email: cape-support@your-org.mil

## License
MIT License - See [LICENSE](LICENSE) file for details.


# Color characterization
# Requirements
  ![Overview](./figures/aim3_overview.png)
## Input
  - scanned image from item I
  - reference from item III
## Output
  - color coordinates in the CIELAB space
  - specific RGB or HSI color ratios as target acceptance criteria
# Software Requirements Specification 
# System and Software Architecture Diagram
# Software Design Specification
``` mermaid
flowchart LR
  A[Device output]
  B[Reference]
  A -- Image --> LAB1[CIELAB1]
  B -- Spectrum --> LAB2[CIELAB2]
  dE[Color characterization]
  LAB1 -->  dE
  LAB2 -->  dE
  dE --> Chart
```
# V&V

# Color characterization
# Requirements
  ![Overview](./figures/aim3_overview.png)
## Input
  - scanned image from item I
  - reference from item III
## Output
  - color coordinates in the CIELAB space
  - specific RGB or HSI color ratios as target acceptance criteria
# Software Requirement Specification 
  - SRS 100: Compare device output with reference in the CIELAB color space
  - SRS 200: Convert device output image to CIELAB
  - SRS 300: Convert reference spectrum to CIELAB
# System and Software Architecture Diagram
``` mermaid
flowchart LR
  subgraph B2 [Image-to-CIELAB]
    CIEXYZ-to-CIELAB
  end

  subgraph B3 [Spectrum-to-CIELAB]
    D65[* D65]
  end

  subgraph B1 [Color characterization]
    Visualization
  end

  A[Scanner under test]
  D[DICOM/ICC_reader]
  T[Test target]
  M[Measurement system]

  T --> A
  T --> M

  A --"WSI DICOM"--> D

  D -- Image in CIEXYZ --> B2
  M -- Spectral transmittance --> B3
  
  Report[Report]
  B2 --CIELAB1-->  B1
  B3 --CIELAB2-->  B1
  
  B1 --Chart--> Report
  style Report fill:none,stroke:none,color:transparent  
```

# Software Design Specification
  - SDS 100: A class for implementing SRS 100
  - SDS 200: A class for implementing SRS 200
  - SDS 300: A class for implementing SRS 300
  
# V&V

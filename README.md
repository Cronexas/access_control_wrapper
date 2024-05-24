


<div id="top"></div>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
<!--
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]
-->


<!-- PROJECT LOGO -->
<!--
<br />
<div align="center">
  <a href="https://github.com/TUK-EIS/VDSProject">
    <img src="doc/figures/TUKL_LOGO_4C.png" alt="Logo" width="400" height="200">
  </a>
  <h3 align="center">
  VDS Class Project
  <br />
  Group #X
  <br />
  Winter Semester 2022/2023
  </h3>

  <p align="center">
    GitHub repository for Verification of Digital Systems Class Project
    <br />
    <br />
    <a href="https://github.com/TUK-EIS/VDSProject/issues">Report Bug</a>
  </p>
</div>
-->

<br />
<br />


<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#general-information">General Information</a>
    </li>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>


## General Information
We are avoiding the fraught terms master/slave and defaulting to host/device where applicable.

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- ABOUT THE PROJECT -->

## About The Project
The access control wrapper is designed with the aim of preventing third-party non-CPU host modules from violating System-on-Chip security. It includes the RISC-V Physical Memory Protection (PMP), Control Status Registers (CSR), a TileLink Uncached Lightweight (TL-UL) CPU interface and an access control logic in the form of a finite state machine with four states: IDLE, BLOCK_START, BLOCK_ERR, BLOCK_IDLE. The PMP configuration can only be written through the CPU interface and is independent of the state of the wrapper. Incoming messages from the host are checked by the PMP during the IDLE state and only pass to the crossbar if they are allowed. Every illegal message gets blocked and the wrapper changes to one of the BLOCK states, where every message from the host to device is blocked, until the CPU requests a return to IDLE und the Host has recivied a TL-UL error response. Messages from Device to Host are always passed, except for the case, when the host hasn't recieved the error-response yet.


The project is split into multiple parts:


#### Create readme.md:
Main tasks in this part:
* Add template for readme.md
* Add project information to readme.md

#### Rework wrapper_structure and add additonal structures:
Main tasks in this part:
* Create structure of wrapper and its units
* Create a structure for the units

#### Implementation of TL-UL Interface for CPU:
Main tasks in this part:
* Implementation of PutFullData and PutPartialData opcode (with all active lanes)
* Implmentation of PutPartialData opcode (without all active lanes)
* Implementation of GET opcode

#### Verifying of TL-UL Interface for CPU:
Main tasks in this part:
* Check if in range beviour of writting data for address-space
* Check out of Range behviour for address-space
* Checking GET 

#### FSM implementation regarding to specification:
Main tasks in this part:
* Implementing FSM base contruct
* Implementing State Transitions

#### Verifying FSM implementation:
Main tasks in this part:
* Verifying all allowed state transitions are correct
* Verifying outputs depending on transition
* Verifying unallowed transitions are not possible

#### Implementation of Interrupt capability regarding to opentitan:
Main tasks in this part:
* Implementing necessary register
* Implementing control for interrupt
  
#### Verifying of Interrupt capability:
Main tasks in this part:
* Verifying interrupt behaviour
  
#### Wrapper Documentation:
Main tasks in this part:
* Create structure of wrapper and its units
* Create a structure for the units

#### Writting theoretical part:
Main tasks in this part:
* State of the Art SoC security. Opentitan as Root of Trust
* Basic idea of wrapper

<p align="right">(<a href="#top">back to top</a>)</p>




<!-- ROADMAP -->
## Roadmap

#### Create readme.md:
- [ ] TODO
- [ ] IN PROGRESS
- [X] DONE

#### Rework wrapper_structure and add additonal structures:
- [X] TODO
- [ ] IN PROGRESS
- [ ] DONE

#### Implementation of TL-UL Interface for CPU:
- [ ] TODO
- [X] IN PROGRESS
- [ ] DONE

#### Verifying of TL-UL Interface for CPU
- [ ] TODO
- [X] IN PROGRESS
- [ ] DONE

#### FSM implementation regarding to specification
- [ ] TODO
- [ ] IN PROGRESS
- [X] DONE

#### Verifying FSM implementation:
- [ ] TODO
- [ ] IN PROGRESS
- [X] DONE

#### Implementation of Interrupt capability regarding to opentitan:
- [X] TODO
- [ ] IN PROGRESS
- [ ] DONE
  
#### Verifying of Interrupt capability:
- [X] TODO
- [ ] IN PROGRESS
- [ ] DONE

#### Wrapper Documentation:
- [ ] TODO
- [X] IN PROGRESS
- [ ] DONE

#### Writting theoretical part:
- [X] TODO
- [ ] IN PROGRESS
- [ ] DONE

      
<p align="right">(<a href="#top">back to top</a>)</p>
<!-- CONTACT -->

## Contact

<!-- Your Name - [@your_twitter](https://twitter.com/your_username) - email@example.com -->
Dominik Schwarz & SECRET - d_schwar@rptu.de & 

<p align="right">(<a href="#top">back to top</a>)</p>

[contributors-shield]: https://img.shields.io/github/contributors/TUK-EIS/VDSProject.svg?style=for-the-badge
[contributors-url]: https://github.com/Cronexas/access_control_wrapper/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/TUK-EIS/VDSProject.svg?style=for-the-badge
[forks-url]: https://github.com/Cronexas/access_control_wrapper/network/members
[stars-shield]: https://img.shields.io/github/stars/TUK-EIS/VDSProject.svg?style=for-the-badge
[stars-url]: https://github.com/Cronexas/access_control_wrapper/stargazers
[issues-shield]: https://img.shields.io/github/issues/TUK-EIS/VDSProject.svg?style=for-the-badge
[issues-url]: https://github.com/Cronexas/access_control_wrapper/issues

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments
Thank you Dino for all your time ,comments and suggestions. It is a pleasure to work with you!



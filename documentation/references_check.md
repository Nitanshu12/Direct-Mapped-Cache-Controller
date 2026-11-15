# References Check

**Checked by:** Mishti Sharma
**Date:** 16 November 2026

## 1. Are the reference details correct?

| No. | Reference | Verification | Correct details / Notes | Source |
|---|---|---|---|---|
| 1 | Hennessy and Patterson, Computer Architecture: A Quantitative Approach | Verified | 6th edition, Morgan Kaufmann. The publisher page gives the publication date 23 November 2017; printed copies and library catalogs show 2019. The report uses 2019. | https://shop.elsevier.com/books/computer-architecture-a-quantitative-approach/hennessy/978-0-12-811905-1 |
| 2 | Patterson and Hennessy, Computer Organization and Design | Verified | 6th edition, MIPS Edition, Morgan Kaufmann, 2020 (publisher date 20 November 2020), ISBN 978-0-12-820109-1. The report must show the edition and the year. | https://www.elsevier.com/books/computer-organization-and-design-mips-edition/patterson/978-0-12-820109-1 |
| 3 | Harris and Harris, Digital Design and Computer Architecture | Verified (edition chosen) | 2nd edition, Morgan Kaufmann, August 2012, authors David Harris and Sarah Harris. A newer RISC-V Edition exists (Morgan Kaufmann, 2021). The report cites the 2nd edition. | https://www.oreilly.com/library/view/-/9780123944245 |
| 4 | A. J. Smith, "Cache Memories" | Verified | ACM Computing Surveys, vol. 14, no. 3, pp. 473-530, September 1982. DOI 10.1145/356887.356892. | https://doi.org/10.1145/356887.356892 |
| 5 | M. D. Hill, "A Case for Direct-Mapped Caches" | Verified | IEEE Computer, vol. 21, no. 12, pp. 25-40, December 1988. DOI 10.1109/2.16187. | https://doi.org/10.1109/2.16187 |
| 6 | N. P. Jouppi, "Improving Direct-Mapped Cache Performance by the Addition of a Small Fully-Associative Cache and Prefetch Buffers" | Verified | 17th Annual International Symposium on Computer Architecture (ISCA '90), May 1990, pp. 364–373. DOI: 10.1145/325164.325162. | https://doi.org/10.1145/325164.325162 |

## 2. Does each reference support what the report says about it?

| Reference | Statement in the Literature Review | Supported? | Note |
|---|---|---|---|
| Smith | Survey of cache design choices (block size, mapping, replacement, write policy) and their effect on miss ratio | Supported | The contents of the paper list Line Size, Placement Algorithm, Replacement Algorithm and Write-Through versus Copy-Back. |
| Hill | Direct-mapped cache needs only one tag comparison, so the hardware is simple and fast | Supported | The abstract says that larger caches and faster hit times favor direct-mapped caches. One tag comparison follows from the definition (a block can be in only one place). |
| Jouppi | A small fully associative victim cache removes many conflict misses of a direct-mapped cache | Supported | The abstract says small victim caches are very effective at removing conflict misses in direct-mapped caches. |
| Hennessy and Patterson (Quantitative Approach) | Temporal and spatial locality; write-through, write-back, write-allocate; the AMAT formula | Not checked | The book was not available. Chapter and page still to be confirmed. |
| Patterson and Hennessy (Computer Organization and Design) | The control of a simple cache is presented as a finite state machine | Not checked | The book was not available. Chapter 5 (memory hierarchy) should be checked. |
| Harris and Harris | Memory structures described in a hardware description language | Not checked | The book was not available. Chapter 4 (HDLs) and the memory systems chapter should be checked. |

No statement was found to be not supported. Three statements about textbooks are not checked yet and are marked honestly.

## 3. One paper I read

**Paper:** N. P. Jouppi, "Improving Direct-Mapped Cache Performance by the Addition of a Small Fully-Associative Cache and Prefetch Buffers," ISCA 1990.

- **Problem the paper solves:** A direct-mapped cache is fast, but two blocks that map to the same line keep replacing each other. These conflict misses cost a lot of time for fast processors.
- **Main idea:** Add a small fully associative victim cache that keeps the blocks just thrown out of the direct-mapped cache, so a conflict miss can be served from it with a short penalty. The paper also adds stream buffers that prefetch the next blocks after a miss. Together they reduce the first-level miss rate by a factor of two to three on six benchmarks.
- **How it relates to our project:** Our conflict trace (addresses 0x30 and 0x430 with the same index) shows exactly this problem, with a 0% hit rate. A victim cache is one possible improvement for future work.


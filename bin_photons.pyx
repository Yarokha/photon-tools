from cpython cimport bool
from timetag_types cimport *
from timetag_types import *

def bin_photons(np.ndarray[np.uint64_t] times, int bin_width, uint64_t start_t=-1, uint64_t end_t=-1, bool include_zeros=True):
        """ bin_photons(times, bin_width, include_zeros=True)

        Bin the given array of photon times in bins of bin_width. The resulting
        bins are returned in a record array containing the fields,
          - start_t (u8)
          - count (u2)
        
        By default, the resulting array includes all bins, even those
        containing no photons. Setting include_zeros to False will result in
        only bins which contain at least one photon.
        """
        cdef unsigned int chunk_sz = 10000
        cdef np.ndarray[Bin] chunk = np.empty(chunk_sz, dtype=bin_dtype)
        chunks = []

        cdef Py_ssize_t i, j
        cdef uint64_t new_start
        cdef uint64_t bin_start = times[0] if start_t == -1 else start_t
        bin_start = (bin_start / bin_width) * bin_width # Make sure we start on bin boundary
        cdef short bin_count = 0
        cdef unsigned int bin = 0

        for i in range(times.shape[0]):
                if times[i] >= bin_start + bin_width:
                        new_start = (times[i] / bin_width) * bin_width
                        chunk[bin].start_t = bin_start
                        chunk[bin].count = bin_count
                        bin += 1
                        if bin == chunk_sz:
                                chunks.append(chunk)
                                chunk = np.empty(chunk_sz, dtype=bin_dtype)
                                bin = 0

                        # Account for zero bins
                        if include_zeros:
                                for j in range(bin_start+bin_width, new_start, bin_width):
                                        chunk[bin].start_t = j
                                        chunk[bin].count = 0
                                        bin += 1
                                        if bin == chunk_sz:
                                                chunks.append(chunk)
                                                chunk = np.empty(chunk_sz, dtype=bin_dtype)
                                                bin = 0

                        bin_count = 0
                        bin_start = new_start

                bin_count += 1

        if include_zeros and end_t != -1:
                for j in range(bin_start+bin_width, end_t, bin_width):
                        chunk[bin].start_t = j
                        chunk[bin].count = 0
                        bin += 1
                        if bin == chunk_sz:
                                chunks.append(chunk)
                                chunk = np.empty(chunk_sz, dtype=bin_dtype)
                                bin = 0

        chunks.append(chunk[:bin])
        return np.hstack(chunks)



// Triangle:
//
// Number of edges / vertices:
const TRI_V: u32 = 3;

// Pentagon:
//
// Number of edges / vertices:
const PEN_V: u32 = 5;
// Number of triangles:
const PEN_T: u32 = PEN_V - 2;
// Total number of vertices when triangulated:
const PEN_VT: u32 = TRI_V * PEN_T;

// Hexagon:
//
// Number of edges / vertices:
const HEX_V: u32 = 6;
// Numwber of triangles:
const HEX_T: u32 = HEX_V - 2;
// Total number of vertices when triangulated:
const HEX_VT: u32 = TRI_V * HEX_T;

// Icosahedron:
//
// Number of vertices:
const ICO_V: u32 = 12;

// Truncated icosahedron:
//
// Number of pentagonal faces:
const TRU_FP: u32 = ICO_V;
// Number of hexagonal faces:
const TRU_FH: u32 = 20;
// Number of triangles:
const TRU_T: u32 = TRU_FP * PEN_VT + TRU_FH * HEX_VT;

pub fn total_vertices(subd: u32) -> u32 {
    if subd == 1 {
        return TRU_T;
    }
    todo!();
}

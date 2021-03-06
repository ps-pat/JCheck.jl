reduce_length(x) = all(<=(length(x)), length.(shrink(x)))

@testset "Shrink methods" begin
    qc = Quickcheck("shrink")

    @add_predicate qc "Reduce string length" s::String -> reduce_length(s)

    @add_predicate(qc,
                   "Reduce vector length",
                   v::Vector{Int} -> reduce_length(v))
    @add_predicate(qc,
                   "Reduce matrix length",
                   M::Matrix{Int} -> reduce_length(M))
    @add_predicate(qc,
                   "Reduce diagonal matrix length",
                   DM::Diagonal{Int} -> reduce_length(DM))
    @add_predicate(qc,
                   "Reduce UnitRange length",
                   UR::UnitRange{Int} -> reduce_length(UR))

    ## `AbstractArray`.
    vec = collect(1:5)
    mat = vcat(vec * vec', vec * vec', vec * vec')
    arr3 = reshape(range(1, 5 * 6 * 7), 5, 6, 7)
    arr4 = reshape(range(1, 5 * 2 * 3 * 4), 5, 2, 3, 4)
    dm = Diagonal(1:5)

    @test shrink(vec) == [collect(1:3), collect(4:5)]
    @test shrink(mat) ==
        [[1 2 3; 2 4 6; 3 6 9; 4 8 12; 5 10 15; 1 2 3; 2 4 6; 3 6 9],
         [4 8 12; 5 10 15; 1 2 3; 2 4 6; 3 6 9; 4 8 12; 5 10 15],
         [4 5; 8 10; 12 15; 16 20; 20 25; 4 5; 8 10; 12 15],
         [16 20; 20 25; 4 5; 8 10; 12 15; 16 20; 20 25]]
    @test shrink(arr3) ==
        [[1 6 11; 2 7 12; 3 8 13;;; 31 36 41; 32 37 42; 33 38 43;;;
          61 66 71; 62 67 72; 63 68 73;;; 91 96 101; 92 97 102; 93 98 103],
         [4 9 14; 5 10 15;;; 34 39 44; 35 40 45;;;
          64 69 74; 65 70 75;;; 94 99 104; 95 100 105],
         [16 21 26; 17 22 27; 18 23 28;;;
          46 51 56; 47 52 57; 48 53 58;;;
          76 81 86; 77 82 87; 78 83 88;;;
          106 111 116; 107 112 117; 108 113 118],
         [19 24 29; 20 25 30;;; 49 54 59; 50 55 60;;;
          79 84 89; 80 85 90;;; 109 114 119; 110 115 120],
         [121 126 131; 122 127 132; 123 128 133;;;
          151 156 161; 152 157 162; 153 158 163;;;
          181 186 191; 182 187 192; 183 188 193],
         [124 129 134; 125 130 135;;;
          154 159 164; 155 160 165;;;
          184 189 194; 185 190 195],
         [136 141 146; 137 142 147; 138 143 148;;;
          166 171 176; 167 172 177; 168 173 178;;;
          196 201 206; 197 202 207; 198 203 208],
         [139 144 149; 140 145 150;;;
          169 174 179; 170 175 180;;;
          199 204 209; 200 205 210]]

    @test shrink(arr4) ==
        [[1; 2; 3;;; 11; 12; 13;;;; 31; 32; 33;;; 41; 42; 43],
         [4; 5;;; 14; 15;;;; 34; 35;;; 44; 45],
         [6; 7; 8;;; 16; 17; 18;;;; 36; 37; 38;;; 46; 47; 48],
         [9; 10;;; 19; 20;;;; 39; 40;;; 49; 50],
         [21; 22; 23;;;; 51; 52; 53],
         [24; 25;;;; 54; 55],
         [26; 27; 28;;;; 56; 57; 58],
         [29; 30;;;; 59; 60],
         [61; 62; 63;;; 71; 72; 73;;;; 91; 92; 93;;; 101; 102; 103],
         [64; 65;;; 74; 75;;;; 94; 95;;; 104; 105],
         [66; 67; 68;;; 76; 77; 78;;;; 96; 97; 98;;; 106; 107; 108],
         [69; 70;;; 79; 80;;;; 99; 100;;; 109; 110],
         [81; 82; 83;;;; 111; 112; 113],
         [84; 85;;;; 114; 115],
         [86; 87; 88;;;; 116; 117; 118],
         [89; 90;;;; 119; 120]]

    @test shrink(dm) == [Diagonal(1:3), Diagonal(4:5)]

    ## `AbstractString`.
    s = "C'est pas de nos affaires, nous on est Iroquois."

    @test shrink(s) ==
        ["C'est pas de nos affaire", "s, nous on est Iroquois."]

    @quickcheck qc
end

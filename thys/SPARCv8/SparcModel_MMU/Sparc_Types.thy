(*
 * Copyright 2016, NTU
 *
 * This software may be distributed and modified according to the terms of
 * the BSD 2-Clause license. Note that NO WARRANTY is provided.
 * See "LICENSE_BSD2.txt" for details.
 *
 * Author: Zhe Hou, David Sanan. 
 *)

section \<open>SPARC V8 architecture CPU model\<close>
theory Sparc_Types    
imports Main "../lib/WordDecl" 
begin

text \<open>The following type definitions are taken from David Sanan's 
definitions for SPARC machines.\<close>

type_synonym machine_word = word32
type_synonym byte = word8
type_synonym phys_address = word36

type_synonym virtua_address = word32
type_synonym page_address = word24
type_synonym offset = word12

type_synonym table_entry = word8

definition page_size :: "word32" where "page_size \<equiv> 4096"

type_synonym virtua_page_address = word20
type_synonym context_type = word8

type_synonym word_length_t1 = word_length8
type_synonym word_length_t2 = word_length6
type_synonym word_length_t3 = word_length6
type_synonym word_length_offset = word_length12
type_synonym word_length_page = word_length24
type_synonym word_length_phys_address = word_length36
type_synonym word_length_virtua_address = word_length32
type_synonym word_length_entry_type = word_length2
type_synonym word_length_machine_word = word_length32

definition length_machine_word :: "nat" 
 where "length_machine_word \<equiv> len_of TYPE(word_length_machine_word)"

text_raw \<open>\newpage\<close>

section \<open>CPU Register Definitions\<close>

text\<open>
 The definitions below come from the SPARC Architecture Manual, Version 8.
 The LEON3 processor has been certified SPARC V8 conformant (2005).
\<close>

definition leon3khz ::"word32"
where
"leon3khz \<equiv> 33000"

text \<open>The following type definitions for MMU is taken from 
David Sanan's definitions for MMU.\<close>

text\<open>
  The definitions below come from the UT699 LEON 3FT/SPARC V8 Microprocessor Functional Manual, 
   Aeroflex, June 20, 2012, p35.
\<close>
datatype MMU_register
 = CR    \<comment>  "Control Register"
 | CTP   \<comment>  "ConText Pointer register"
 | CNR   \<comment>  "Context Register"
 | FTSR   \<comment>  "Fault Status Register"
 | FAR   \<comment>  "Fault Address Register"

lemma MMU_register_induct: 
  "P CR \<Longrightarrow> P CTP \<Longrightarrow> P CNR \<Longrightarrow> P FTSR \<Longrightarrow> P FAR 
   \<Longrightarrow> P x"
  by (cases x) auto

lemma UNIV_MMU_register [no_atp]: "UNIV = {CR, CTP, CNR, FTSR, FAR}"
   apply (safe)
   apply (case_tac x)
   apply (auto intro:MMU_register_induct)
  done


instantiation MMU_register :: enum begin

definition "enum_MMU_register = [ CR, CTP, CNR, FTSR, FAR ]"

definition
  "enum_all_MMU_register P \<longleftrightarrow> P CR \<and> P CTP \<and> P CNR \<and> P FTSR \<and> P FAR "
definition
  "enum_ex_MMU_register P \<longleftrightarrow> P CR \<or> P CTP \<or> P CNR \<or> P FTSR \<or> P FAR"

 instance proof
  qed (simp_all only: enum_MMU_register_def enum_all_MMU_register_def 
                      enum_ex_MMU_register_def UNIV_MMU_register, simp_all)
end
type_synonym MMU_context = "MMU_register \<Rightarrow> machine_word"

text \<open>\<open>PTE_flags\<close> is the last 8 bits of a PTE. See page 242 of SPARCv8 manual.
\<^item> C - bit 7
\<^item> M - bit 6,
\<^item> R - bit 5
\<^item> ACC - bit 4~2
\<^item> ET - bit 1~0.\<close>

type_synonym PTE_flags = word8

text \<open>
  @{term CPU_register} datatype is an enumeration with the CPU registers defined in the SPARC V8 
  architecture.
\<close>
datatype CPU_register = 
   PSR   \<comment>   "Processor State Register"
 | WIM   \<comment>   "Window Invalid Mask"
 | TBR   \<comment>   "Trap Base Register"
 | Y     \<comment>   "Multiply/Divide Register"
 | PC    \<comment>   "Program Counter"
 | nPC   \<comment>   "next Program Counter"
 | DTQ   \<comment>   "Deferred-Trap Queue"
 | FSR   \<comment>   "Floating-Point State Register"
 | FQ    \<comment>   "Floating-Point Deferred-Trap Queue"
 | CSR   \<comment>   "Coprocessor State Register"
 | CQ    \<comment>   "Coprocessor Deferred-Trap Queue"
 (*| CCR   --   "Cache Control Register"*)
 | ASR "word5"  \<comment>   "Ancillary State Register"

text \<open>The following two functions are dummies since we will not use 
        ASRs. Future formalisation may add more details to this.\<close>

definition privileged_ASR :: "word5 \<Rightarrow> bool"
where
"privileged_ASR r \<equiv> False
"

definition illegal_instruction_ASR :: "word5 \<Rightarrow> bool"
where
"illegal_instruction_ASR r \<equiv> False
"

definition get_tt :: "word32 \<Rightarrow> word8"
where
"get_tt tbr \<equiv>
  ucast ((bitAND tbr 0b00000000000000000000111111110000) >> 4)
"

text \<open>Write the tt field of the TBR register. 
        Return the new value of TBR.\<close>
definition write_tt :: "word8 \<Rightarrow> word32 \<Rightarrow> word32"
where
"write_tt new_tt_val tbr_val \<equiv>
  let tmp = bitAND tbr_val 0b111111111111111111111000000001111 in
      bitOR tmp (((ucast new_tt_val)::word32) << 4)
"

text \<open>Get the nth bit of WIM. This equals (bitAND WIM $2^n$). 
        N.B. the first bit of WIM is the 0th bit.\<close>
definition get_WIM_bit :: "nat \<Rightarrow> word32 \<Rightarrow> word1"
where
"get_WIM_bit n wim \<equiv>
  let mask = ((ucast (0b1::word1))::word32) << n in
  ucast ((bitAND mask wim) >> n)
"

definition get_CWP :: "word32 \<Rightarrow> word5"
where
"get_CWP psr \<equiv> 
  ucast (bitAND psr 0b00000000000000000000000000011111) 
"

definition get_ET :: "word32 \<Rightarrow> word1"
where
"get_ET psr \<equiv> 
  ucast ((bitAND psr 0b00000000000000000000000000100000) >> 5) 
"

definition get_PIL :: "word32 \<Rightarrow> word4"
where
"get_PIL psr \<equiv> 
  ucast ((bitAND psr 0b00000000000000000000111100000000) >> 8) 
"

definition get_PS :: "word32 \<Rightarrow> word1"
where
"get_PS psr \<equiv> 
  ucast ((bitAND psr 0b00000000000000000000000001000000) >> 6) 
"

definition get_S :: "word32 \<Rightarrow> word1"
where
"get_S psr \<equiv> 
  \<^cancel>\<open>ucast ((bitAND psr 0b00000000000000000000000010000000) >> 7)\<close>
  if (bitAND psr (0b00000000000000000000000010000000::word32)) = 0 then 0
  else 1
"

definition get_icc_N :: "word32 \<Rightarrow> word1"
where
"get_icc_N psr \<equiv>
  ucast ((bitAND psr 0b00000000100000000000000000000000) >> 23)
"

definition get_icc_Z :: "word32 \<Rightarrow> word1"
where
"get_icc_Z psr \<equiv>
  ucast ((bitAND psr 0b00000000010000000000000000000000) >> 22)
"

definition get_icc_V :: "word32 \<Rightarrow> word1"
where
"get_icc_V psr \<equiv>
  ucast ((bitAND psr 0b00000000001000000000000000000000) >> 21)
"

definition get_icc_C :: "word32 \<Rightarrow> word1"
where
"get_icc_C psr \<equiv>
  ucast ((bitAND psr 0b00000000000100000000000000000000) >> 20)
"

definition update_S :: "word1 \<Rightarrow> word32 \<Rightarrow> word32"
where
"update_S s_val psr_val \<equiv>
  let tmp0 = bitAND psr_val 0b11111111111111111111111101111111 in
  bitOR tmp0 (((ucast s_val)::word32) << 7)
"

text \<open>Update the CWP field of PSR. 
        Return the new value of PSR.\<close>
definition update_CWP :: "word5 \<Rightarrow> word32 \<Rightarrow> word32"
where
"update_CWP cwp_val psr_val \<equiv>
  let tmp0 = bitAND psr_val (0b11111111111111111111111111100000::word32);
      s_val = ((ucast (get_S psr_val))::word1)
  in
  if s_val = 0 then  
    bitAND (bitOR tmp0 ((ucast cwp_val)::word32)) (0b11111111111111111111111101111111::word32)
  else
    bitOR (bitOR tmp0 ((ucast cwp_val)::word32)) (0b00000000000000000000000010000000::word32)
"

text \<open>Update the the ET, CWP, and S fields of PSR. 
        Return the new value of PSR.\<close>
definition update_PSR_rett :: "word5 \<Rightarrow> word1 \<Rightarrow> word1 \<Rightarrow> word32 \<Rightarrow> word32"
where
"update_PSR_rett cwp_val et_val s_val psr_val \<equiv>
  let tmp0 = bitAND psr_val 0b11111111111111111111111101000000;
      tmp1 = bitOR tmp0 ((ucast cwp_val)::word32);
      tmp2 = bitOR tmp1 (((ucast et_val)::word32) << 5); 
      tmp3 = bitOR tmp2 (((ucast s_val)::word32) << 7)
  in  
  tmp3
"

definition update_PSR_exe_trap :: "word5 \<Rightarrow> word1 \<Rightarrow> word1 \<Rightarrow> word32 \<Rightarrow> word32"
where
"update_PSR_exe_trap cwp_val et_val ps_val psr_val \<equiv>
  let tmp0 = bitAND psr_val 0b11111111111111111111111110000000;
      tmp1 = bitOR tmp0 ((ucast cwp_val)::word32);
      tmp2 = bitOR tmp1 (((ucast et_val)::word32) << 5); 
      tmp3 = bitOR tmp2 (((ucast ps_val)::word32) << 6)
  in  
  tmp3
"

text \<open>Update the N, Z, V, C fields of PSR. 
        Return the new value of PSR.\<close>
definition update_PSR_icc :: "word1 \<Rightarrow> word1 \<Rightarrow> word1 \<Rightarrow> word1 \<Rightarrow> word32 \<Rightarrow> word32"
where
"update_PSR_icc n_val z_val v_val c_val psr_val \<equiv>
  let
      n_val_32 = if n_val = 0 then 0 
                 else       (0b00000000100000000000000000000000::word32); 
      z_val_32 = if z_val = 0 then 0 
                 else       (0b00000000010000000000000000000000::word32); 
      v_val_32 = if v_val = 0 then 0 
                 else       (0b00000000001000000000000000000000::word32);
      c_val_32 = if c_val = 0 then 0 
                 else       (0b00000000000100000000000000000000::word32);
      tmp0 = bitAND psr_val (0b11111111000011111111111111111111::word32);
      tmp1 = bitOR tmp0 n_val_32;
      tmp2 = bitOR tmp1 z_val_32;
      tmp3 = bitOR tmp2 v_val_32;
      tmp4 = bitOR tmp3 c_val_32
  in
  tmp4
"

text \<open>Update the ET, PIL fields of PSR. 
        Return the new value of PSR.\<close>
definition update_PSR_et_pil :: "word1 \<Rightarrow> word4 \<Rightarrow> word32 \<Rightarrow> word32"
where
"update_PSR_et_pil et pil psr_val \<equiv>
  let tmp0 = bitAND psr_val 0b111111111111111111111000011011111;
      tmp1 = bitOR tmp0 (((ucast et)::word32) << 5);
      tmp2 = bitOR tmp1 (((ucast pil)::word32) << 8)
  in
  tmp2
"

text \<open>
   SPARC V8 architecture is organized in windows of 32 user registers.
   The data stored in a register is defined as a 32 bits word @{term reg_type}:
\<close>
type_synonym reg_type = "word32"

text \<open>
  The access to the value of a CPU register of type @{term CPU_register} is
  defined by a total function @{term cpu_context}
\<close>

type_synonym cpu_context = "CPU_register \<Rightarrow> reg_type"

text \<open>
  User registers are defined with the type @{term user_reg} represented by a 5 bits word.
\<close>

type_synonym user_reg_type = "word5"

definition PSR_S ::"reg_type"
where "PSR_S \<equiv> 6"
text \<open>
  Each window context is defined by a total function @{term window_context} from @{term user_register} 
  to @{term reg_type} (32 bits word storing the actual value of the register).
\<close>

type_synonym window_context = "user_reg_type \<Rightarrow> reg_type"
text \<open>
  The number of windows is implementation dependent. 
  The LEON architecture is composed of 16 different windows (a 4 bits word).
\<close>

definition NWINDOWS :: "int"
where "NWINDOWS \<equiv> 8"

text \<open>Maximum number of windows is 32 in SPARCv8.\<close>
type_synonym ('a) window_size = "'a word"

text \<open>
Finally the user context is defined by another total function @{term user_context} from 
@{term window_size} to @{term window_context}. That is, the user context is a function taking as
argument a register set window and a register within that window, and it returns the value stored
in that user register.
\<close>
type_synonym ('a) user_context = "('a) window_size \<Rightarrow> window_context"

datatype sys_reg = 
         CCR    \<comment>  "Cache control register"
        |ICCR   \<comment>  "Instruction cache configuration register"
        |DCCR   \<comment>  "Data cache configuration register"

type_synonym sys_context = "sys_reg \<Rightarrow> reg_type"

text\<open>
The memory model is defined by a total function from 32 bits words to 8 bits words
\<close>
type_synonym asi_type = "word8"

text \<open>
 The memory is defined as a function from page address to page, which is also defined
  as a function from physical address to @{term "machine_word"}
\<close>

type_synonym mem_val_type = "word8"
type_synonym mem_context = "asi_type \<Rightarrow> phys_address \<Rightarrow> mem_val_type option"

type_synonym cache_tag = "word20"
type_synonym cache_line_size = "word12"
type_synonym cache_type = "(cache_tag \<times> cache_line_size)"
type_synonym cache_context = "cache_type \<Rightarrow> mem_val_type option"

text \<open>The delayed-write pool generated from write state register instructions.\<close>
type_synonym delayed_write_pool = "(int \<times> reg_type \<times> CPU_register) list"

definition DELAYNUM :: "int"
where "DELAYNUM \<equiv> 0"

text \<open>Convert a set to a list.\<close>
definition list_of_set :: "'a set \<Rightarrow> 'a list"
  where "list_of_set s = (SOME l. set l = s)"

lemma set_list_of_set: "finite s \<Longrightarrow> set (list_of_set s) = s"
unfolding list_of_set_def 
by (metis (mono_tags) finite_list some_eq_ex)

type_synonym ANNUL = "bool"
type_synonym RESET_TRAP = "bool"
type_synonym EXECUTE_MODE = "bool"
type_synonym RESET_MODE = "bool"
type_synonym ERROR_MODE = "bool"
type_synonym TICC_TRAP_TYPE = "word7"
type_synonym INTERRUPT_LEVEL = "word3"
type_synonym STORE_BARRIER_PENDING = "bool"

text \<open>The processor asserts this signal to ensure that the
memory system will not process another SWAP or
LDSTUB operation to the same memory byte.\<close>
type_synonym pb_block_ldst_byte = "virtua_address \<Rightarrow> bool"

text\<open>The processor asserts this signal to ensure that the
memory system will not process another SWAP or
LDSTUB operation to the same memory word.\<close>
type_synonym pb_block_ldst_word = "virtua_address \<Rightarrow> bool"

record sparc_state_var =
annul:: ANNUL
resett:: RESET_TRAP
exe:: EXECUTE_MODE
reset:: RESET_MODE
err:: ERROR_MODE
ticc:: TICC_TRAP_TYPE
itrpt_lvl:: INTERRUPT_LEVEL
st_bar:: STORE_BARRIER_PENDING
atm_ldst_byte:: pb_block_ldst_byte
atm_ldst_word:: pb_block_ldst_word

definition get_annul :: "sparc_state_var \<Rightarrow> bool"
where "get_annul v \<equiv> annul v"

definition get_reset_trap :: "sparc_state_var \<Rightarrow> bool"
where "get_reset_trap v \<equiv> resett v"

definition get_exe_mode :: "sparc_state_var \<Rightarrow> bool"
where "get_exe_mode v \<equiv> exe v"

definition get_reset_mode :: "sparc_state_var \<Rightarrow> bool"
where "get_reset_mode v \<equiv> reset v"

definition get_err_mode :: "sparc_state_var \<Rightarrow> bool"
where "get_err_mode v \<equiv> err v"

definition get_ticc_trap_type :: "sparc_state_var \<Rightarrow> word7"
where "get_ticc_trap_type v \<equiv> ticc v"

definition get_interrupt_level :: "sparc_state_var \<Rightarrow> word3"
where "get_interrupt_level v \<equiv> itrpt_lvl v"

definition get_store_barrier_pending :: "sparc_state_var \<Rightarrow> bool"
where "get_store_barrier_pending v \<equiv> st_bar v"

definition write_annul :: "bool \<Rightarrow> sparc_state_var \<Rightarrow> sparc_state_var"
where "write_annul b v \<equiv> v\<lparr>annul := b\<rparr>"

definition write_reset_trap :: "bool \<Rightarrow> sparc_state_var \<Rightarrow> sparc_state_var"
where "write_reset_trap b v \<equiv> v\<lparr>resett := b\<rparr>"

definition write_exe_mode :: "bool \<Rightarrow> sparc_state_var \<Rightarrow> sparc_state_var"
where "write_exe_mode b v \<equiv> v\<lparr>exe := b\<rparr>"

definition write_reset_mode :: "bool \<Rightarrow> sparc_state_var \<Rightarrow> sparc_state_var"
where "write_reset_mode b v \<equiv> v\<lparr>reset := b\<rparr>"

definition write_err_mode :: "bool \<Rightarrow> sparc_state_var \<Rightarrow> sparc_state_var"
where "write_err_mode b v \<equiv> v\<lparr>err := b\<rparr>"

definition write_ticc_trap_type :: "word7 \<Rightarrow> sparc_state_var \<Rightarrow> sparc_state_var"
where "write_ticc_trap_type w v \<equiv> v\<lparr>ticc := w\<rparr>"

definition write_interrupt_level :: "word3 \<Rightarrow> sparc_state_var \<Rightarrow> sparc_state_var"
where "write_interrupt_level w v \<equiv> v\<lparr>itrpt_lvl := w\<rparr>"

definition write_store_barrier_pending :: "bool \<Rightarrow> sparc_state_var \<Rightarrow> sparc_state_var"
where "write_store_barrier_pending b v \<equiv> v\<lparr>st_bar := b\<rparr>"

text \<open>Given a word7 value, find the highest bit,
        and fill the left bits to be the highest bit.\<close>
definition sign_ext7::"word7 \<Rightarrow> word32"
where
"sign_ext7 w \<equiv> 
  let highest_bit = (bitAND w 0b1000000) >> 6 in
  if highest_bit = 0 then
    (ucast w)::word32
  else bitOR ((ucast w)::word32) 0b11111111111111111111111110000000
"

definition zero_ext8 :: "word8 \<Rightarrow> word32"
where
"zero_ext8 w \<equiv> (ucast w)::word32
"

text \<open>Given a word8 value, find the highest bit,
        and fill the left bits to be the highest bit.\<close>
definition sign_ext8::"word8 \<Rightarrow> word32"
where
"sign_ext8 w \<equiv> 
  let highest_bit = (bitAND w 0b10000000) >> 7 in
  if highest_bit = 0 then
    (ucast w)::word32
  else bitOR ((ucast w)::word32) 0b11111111111111111111111100000000
"

text \<open>Given a word13 value, find the highest bit,
        and fill the left bits to be the highest bit.\<close>
definition sign_ext13::"word13 \<Rightarrow> word32"
where
"sign_ext13 w \<equiv> 
  let highest_bit = (bitAND w 0b1000000000000) >> 12 in
  if highest_bit = 0 then
    (ucast w)::word32
  else bitOR ((ucast w)::word32) 0b11111111111111111110000000000000
"

definition zero_ext16 :: "word16 \<Rightarrow> word32"
where
"zero_ext16 w \<equiv> (ucast w)::word32
"

text \<open>Given a word16 value, find the highest bit,
        and fill the left bits to be the highest bit.\<close>
definition sign_ext16::"word16 \<Rightarrow> word32"
where
"sign_ext16 w \<equiv> 
  let highest_bit = (bitAND w 0b1000000000000000) >> 15 in
  if highest_bit = 0 then
    (ucast w)::word32
  else bitOR ((ucast w)::word32) 0b11111111111111110000000000000000
"

text \<open>Given a word22 value, find the highest bit,
        and fill the left bits to tbe the highest bit.\<close>
definition sign_ext22::"word22 \<Rightarrow> word32"
where
"sign_ext22 w \<equiv>
  let highest_bit = (bitAND w 0b1000000000000000000000) >> 21 in
  if highest_bit = 0 then
    (ucast w)::word32
  else bitOR ((ucast w)::word32) 0b11111111110000000000000000000000
"

text \<open>Given a word24 value, find the highest bit,
        and fill the left bits to tbe the highest bit.\<close>
definition sign_ext24::"word24 \<Rightarrow> word32"
where
"sign_ext24 w \<equiv>
  let highest_bit = (bitAND w 0b100000000000000000000000) >> 23 in
  if highest_bit = 0 then
    (ucast w)::word32
  else bitOR ((ucast w)::word32) 0b11111111000000000000000000000000
"

text\<open>
Operations to be defined.
The SPARC V8 architecture is composed of the following set of instructions:
  \<^item> Load Integer Instructions
  \<^item> Load Floating-point Instructions
  \<^item> Load Coprocessor Instructions
  \<^item> Store Integer Instructions
  \<^item> Store Floating-point Instructions
  \<^item> Store Coprocessor Instructions
  \<^item> Atomic Load-Store Unsigned Byte Instructions
  \<^item> SWAP Register With Memory Instruction
  \<^item> SETHI Instructions
  \<^item> NOP Instruction
  \<^item> Logical Instructions
  \<^item> Shift Instructions
  \<^item> Add Instructions
  \<^item> Tagged Add Instructions
  \<^item> Subtract Instructions
  \<^item> Tagged Subtract Instructions
  \<^item> Multiply Step Instruction
  \<^item> Multiply Instructions
  \<^item> Divide Instructions
  \<^item> SAVE and RESTORE Instructions
  \<^item> Branch on Integer Condition Codes Instructions
  \<^item> Branch on Floating-point Condition Codes Instructions
  \<^item> Branch on Coprocessor Condition Codes Instructions
  \<^item> Call and Link Instruction
  \<^item> Jump and Link Instruction
  \<^item> Return from Trap Instruction
  \<^item> Trap on Integer Condition Codes Instructions
  \<^item> Read State Register Instructions
  \<^item> Write State Register Instructions
  \<^item> STBAR Instruction
  \<^item> Unimplemented Instruction
  \<^item> Flush Instruction Memory
  \<^item> Floating-point Operate (FPop) Instructions
  \<^item> Convert Integer to Floating point Instructions
  \<^item> Convert Floating point to Integer Instructions
  \<^item> Convert Between Floating-point Formats Instructions
  \<^item> Floating-point Move Instructions
  \<^item> Floating-point Square Root Instructions
  \<^item> Floating-point Add and Subtract Instructions
  \<^item> Floating-point Multiply and Divide Instructions
  \<^item> Floating-point Compare Instructions
  \<^item> Coprocessor Operate Instructions
\<close>

text \<open>The CALL instruction.\<close>
datatype call_type = CALL \<comment> "Call and Link"

text \<open>The SETHI instruction.\<close>
datatype sethi_type = SETHI    \<comment>    "Set High 22 bits of r Register"

text \<open>The NOP instruction.\<close>
datatype nop_type = NOP      \<comment>    "No Operation"

text \<open>The Branch on integer condition codes instructions.\<close> 
datatype bicc_type = 
  BE       \<comment>    "Branch on Equal"
 | BNE      \<comment>    "Branch on Not Equal"
 | BGU      \<comment>    "Branch on Greater Unsigned"
 | BLE      \<comment>    "Branch on Less or Equal"
 | BL       \<comment>    "Branch on Less"
 | BGE      \<comment>    "Branch on Greater or Equal"
 | BNEG     \<comment>    "Branch on Negative"
 | BG       \<comment>    "Branch on Greater"
 | BCS      \<comment>    "Branch on Carry Set (Less than, Unsigned)"
 | BLEU     \<comment>    "Branch on Less or Equal Unsigned"
 | BCC      \<comment>    "Branch on Carry Clear (Greater than or Equal, Unsigned)"
 | BA       \<comment>    "Branch Always"
 | BN       \<comment>    "Branch Never" \<comment> \<open>Added for unconditional branches\<close>
 | BPOS     \<comment>  "Branch on Positive"
 | BVC      \<comment>  "Branch on Overflow Clear"
 | BVS      \<comment>  "Branch on Overflow Set"

text \<open>Memory instructions. That is, load and store.\<close>
datatype load_store_type =
  LDSB     \<comment>    "Load Signed Byte"
 | LDUB     \<comment>    "Load Unsigned Byte"
 | LDUBA    \<comment>    "Load Unsigned Byte from Alternate space"
 | LDUH     \<comment>    "Load Unsigned Halfword"
 | LD       \<comment>    "Load Word"
 | LDA      \<comment>    "Load Word from Alternate space"
 | LDD      \<comment>    "Load Doubleword"
 | STB      \<comment>    "Store Byte"
 | STH      \<comment>    "Store Halfword"
 | ST       \<comment>    "Store Word"
 | STA      \<comment>    "Store Word into Alternate space"
 | STD      \<comment>    "Store Doubleword"
 | LDSBA    \<comment>  "Load Signed Byte from Alternate space"
 | LDSH     \<comment>  "Load Signed Halfword"
 | LDSHA    \<comment>  "Load Signed Halfword from Alternate space"
 | LDUHA    \<comment>  "Load Unsigned Halfword from Alternate space"
 | LDDA     \<comment>  "Load Doubleword from Alternate space"
 | STBA     \<comment>  "Store Byte into Alternate space"
 | STHA     \<comment>  "Store Halfword into Alternate space"
 | STDA     \<comment>  "Store Doubleword into Alternate space"
 | LDSTUB   \<comment>  "Atomic Load Store Unsigned Byte"
 | LDSTUBA  \<comment>  "Atomic Load Store Unsinged Byte in Alternate space"
 | SWAP     \<comment>  "Swap r Register with Mmemory"
 | SWAPA    \<comment>  "Swap r Register with Mmemory in Alternate space"
 | FLUSH    \<comment>    "Flush Instruction Memory"
 | STBAR    \<comment>  "Store Barrier"

text \<open>Arithmetic instructions.\<close>
datatype arith_type =
  ADD      \<comment>    "Add"
 | ADDcc    \<comment>    "Add and modify icc"
 | ADDX     \<comment>    "Add with Carry"
 | SUB      \<comment>    "Subtract"
 | SUBcc    \<comment>    "Subtract and modify icc"
 | SUBX     \<comment>    "Subtract with Carry"
 | UMUL     \<comment>    "Unsigned Integer Multiply"
 | SMUL     \<comment>    "Signed Integer Multiply"
 | SMULcc   \<comment>    "Signed Integer Multiply and modify icc"
 | UDIV     \<comment>    "Unsigned Integer Divide"
 | UDIVcc   \<comment>    "Unsigned Integer Divide and modify icc"
 | SDIV     \<comment>    "Signed Integer Divide" 
 | ADDXcc   \<comment>  "Add with Carry and modify icc"
 | TADDcc   \<comment>  "Tagged Add and modify icc"
 | TADDccTV \<comment>  "Tagged Add and modify icc and Trap on overflow"
 | SUBXcc   \<comment>  "Subtract with Carry and modify icc"
 | TSUBcc   \<comment>  "Tagged Subtract and modify icc"
 | TSUBccTV \<comment>  "Tagged Subtract and modify icc and Trap on overflow"
 | MULScc   \<comment>  "Multiply Step and modify icc"
 | UMULcc   \<comment>  "Unsigned Integer Multiply and modify icc"
 | SDIVcc   \<comment>  "Signed Integer Divide and modify icc"

text \<open>Logical instructions.\<close>
datatype logic_type =
  ANDs      \<comment>    "And"
 | ANDcc    \<comment>    "And and modify icc"
 | ANDN     \<comment>    "And Not"
 | ANDNcc   \<comment>    "And Not and modify icc"
 | ORs       \<comment>    "Inclusive-Or"
 | ORcc     \<comment>    "Inclusive-Or and modify icc"
 | ORN      \<comment>    "Inclusive Or Not"
 | XORs      \<comment>    "Exclusive-Or"
 | XNOR     \<comment>    "Exclusive-Nor"
 | ORNcc    \<comment>  "Inclusive-Or Not and modify icc"
 | XORcc    \<comment>  "Exclusive-Or and modify icc"
 | XNORcc   \<comment>  "Exclusive-Nor and modify icc"
 
text \<open>Shift instructions.\<close>
datatype shift_type =
  SLL      \<comment>    "Shift Left Logical"
 | SRL      \<comment>    "Shift Right Logical"
 | SRA      \<comment>    "Shift Right Arithmetic" 

text \<open>Other Control-transfer instructions.\<close>
datatype ctrl_type = 
  JMPL     \<comment>    "Jump and Link"
 | RETT     \<comment>    "Return from Trap"
 | SAVE     \<comment>    "Save caller's window"
 | RESTORE  \<comment>    "Restore caller's window" 

text \<open>Access state registers instructions.\<close>
datatype sreg_type =
  RDASR    \<comment>    "Read Ancillary State Register"
 | RDY      \<comment>    "Read Y Register"
 | RDPSR    \<comment>    "Read Processor State Register"
 | RDWIM    \<comment>    "Read Window Invalid Mask Register"
 | RDTBR    \<comment>    "Read Trap Base Regiser"
 | WRASR    \<comment>    "Write Ancillary State Register"
 | WRY      \<comment>    "Write Y Register"
 | WRPSR    \<comment>    "Write Processor State Register"
 | WRWIM    \<comment>    "Write Window Invalid Mask Register"
 | WRTBR    \<comment>    "Write Trap Base Register" 

text \<open>Unimplemented instruction.\<close>
datatype uimp_type = UNIMP    \<comment>  "Unimplemented" 

text \<open>Trap on integer condition code instructions.\<close>
datatype ticc_type =
 TA       \<comment>  "Trap Always"
 | TN       \<comment>  "Trap Never"
 | TNE      \<comment>  "Trap on Not Equal"
 | TE       \<comment>  "Trap on Equal"
 | TG       \<comment>  "Trap on Greater"
 | TLE      \<comment>  "Trap on Less or Equal"
 | TGE      \<comment>  "Trap on Greater or Equal"
 | TL       \<comment>  "Trap on Less"
 | TGU      \<comment>  "Trap on Greater Unsigned"
 | TLEU     \<comment>  "Trap on Less or Equal Unsigned"
 | TCC      \<comment>  "Trap on Carry Clear (Greater than or Equal, Unsigned)"
 | TCS      \<comment>  "Trap on Carry Set (Less Than, Unsigned)"
 | TPOS     \<comment>  "Trap on Postive"
 | TNEG     \<comment>  "Trap on Negative"
 | TVC      \<comment>  "Trap on Overflow Clear"
 | TVS      \<comment>  "Trap on Overflow Set"

datatype sparc_operation =
  call_type call_type
 | sethi_type sethi_type
 | nop_type nop_type
 | bicc_type bicc_type
 | load_store_type load_store_type
 | arith_type arith_type
 | logic_type logic_type
 | shift_type shift_type
 | ctrl_type ctrl_type
 | sreg_type sreg_type
 | uimp_type uimp_type
 | ticc_type ticc_type

datatype Trap = 
reset 
|data_store_error
|instruction_access_MMU_miss
|instruction_access_error
|r_register_access_error
|instruction_access_exception
|privileged_instruction
|illegal_instruction
|unimplemented_FLUSH
|watchpoint_detected
|fp_disabled
|cp_disabled
|window_overflow
|window_underflow
|mem_address_not_aligned
|fp_exception
|cp_exception
|data_access_error
|data_access_MMU_miss
|data_access_exception
|tag_overflow
|division_by_zero
|trap_instruction
|interrupt_level_n

datatype Exception =
\<comment> \<open>The following are processor states that are not in the instruction model,\<close>
\<comment> \<open>but we MAY want to deal with these from hardware perspective.\<close>
\<comment> \<open>\<open>|execute_mode\<close>\<close>
\<comment> \<open>\<open>|reset_mode\<close>\<close>
\<comment> \<open>\<open>|error_mode\<close>\<close>
\<comment> \<open>The following are self-defined exceptions.\<close>
invalid_cond_f2
|invalid_op2_f2
|illegal_instruction2 \<comment> \<open>when \<open>i = 0\<close> for load/store not from alternate space\<close>
|invalid_op3_f3_op11
|case_impossible
|invalid_op3_f3_op10
|invalid_op_f3
|unsupported_instruction
|fetch_instruction_error
|invalid_trap_cond

end

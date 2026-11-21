// Mraa3dssFix.cs - "MRAA 3DSS Fix" recipe for the Stalker Anomaly Vanilla+ Coop Pack.
//
// 3DSS MRAA and "MRAA 1.4 meshes for 3DSS MRAA" were made for MRAA 1.3. Their weapon models
// still name MRAA 1.3's animation files, which do not match MRAA 1.4.6. This recipe rebuilds
// the fix on each PC from those mods' own files (nothing of theirs ships with the pack):
//   1. every 3DSS model whose animation reference differs from MRAA 1.4.6's model gets
//      MRAA 1.4.6's reference written into it;
//   2. where a 3DSS model has extra bones (wpn_scoped_hide / wpn_scoped_unhide) that the
//      MRAA 1.4.6 animation file lacks, a copy of that animation file gets those bones added,
//      held still at the model's bind pose (named *_vpcp3dss.omf);
//   3. the P90 model is resized to 0.9 (MRAA 1.4.6 shrank its P90).
// The caller checks every output file against the pack owner's SHA-256 list.
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

public static class Mraa3dssFix
{
    struct Chunk { public uint Id; public int Off; public int Size; }

    static List<Chunk> Chunks(byte[] b, int o, int end, bool strict)
    {
        var list = new List<Chunk>();
        while (o + 8 <= end)
        {
            uint id = BitConverter.ToUInt32(b, o);
            int s = (int)BitConverter.ToUInt32(b, o + 4);
            list.Add(new Chunk { Id = id, Off = o + 8, Size = s });
            o += 8 + s;
        }
        if (strict && o != end) throw new InvalidDataException("chunk sizes do not add up");
        return list;
    }

    static Dictionary<uint, Chunk> TopMasked(byte[] b, int o, int end)
    {
        var d = new Dictionary<uint, Chunk>();
        foreach (var c in Chunks(b, o, end, false)) d[c.Id & 0x7fffffffu] = c;
        return d;
    }

    static Dictionary<uint, Chunk> StrictMasked(byte[] b)
    {
        var d = new Dictionary<uint, Chunk>();
        foreach (var c in Chunks(b, 0, b.Length, true)) d[c.Id & 0x7fffffffu] = c;
        return d;
    }

    static string ZStr(byte[] d, ref int q)
    {
        int e = Array.IndexOf<byte>(d, 0, q);
        if (e < 0) throw new InvalidDataException("unterminated string");
        string s = Encoding.ASCII.GetString(d, q, e - q);
        q = e + 1;
        return s;
    }

    static byte[] Pack(uint id, byte[] data)
    {
        var r = new byte[8 + data.Length];
        Buffer.BlockCopy(BitConverter.GetBytes(id), 0, r, 0, 4);
        Buffer.BlockCopy(BitConverter.GetBytes((uint)data.Length), 0, r, 4, 4);
        Buffer.BlockCopy(data, 0, r, 8, data.Length);
        return r;
    }

    // model: animation reference + bone names
    static void Info(string path, out string reference, out List<string> bones)
    {
        byte[] b = File.ReadAllBytes(path);
        var c = TopMasked(b, 0, b.Length);
        reference = null;
        Chunk k;
        if (c.TryGetValue(24, out k)) { int q = k.Off + 4; reference = ZStr(b, ref q); }
        else if (c.TryGetValue(19, out k)) { int q = k.Off; reference = ZStr(b, ref q); }
        k = c[13];
        int p = k.Off;
        uint n = BitConverter.ToUInt32(b, p); p += 4;
        bones = new List<string>();
        for (uint i = 0; i < n; i++)
        {
            bones.Add(ZStr(b, ref p));
            ZStr(b, ref p);   // parent
            p += 60;          // obb
        }
    }

    // bind pose (rotation, position) of every bone, from the model's IK data
    static Dictionary<string, float[]> BindPose(string path)
    {
        byte[] b = File.ReadAllBytes(path);
        var c = StrictMasked(b);
        string r; List<string> names;
        Info(path, out r, out names);
        var k = c[16];
        int q = k.Off;
        var res = new Dictionary<string, float[]>();
        foreach (var nm in names)
        {
            uint ver = BitConverter.ToUInt32(b, q); q += 4;
            ZStr(b, ref q);   // game material
            q += 112;         // shape
            q += 4 + 48 + 8 + 4 + 8 + (ver > 0 ? 4 : 0);
            var v = new float[6];
            for (int i = 0; i < 6; i++) v[i] = BitConverter.ToSingle(b, q + 4 * i);
            q += 24 + 4 + 12;
            res[nm] = v;
        }
        return res;
    }

    static int IndexOf(byte[] hay, int start, int len, byte[] needle)
    {
        int end = start + len - needle.Length;
        for (int i = start; i <= end; i++)
        {
            int j = 0;
            while (j < needle.Length && hay[i + j] == needle[j]) j++;
            if (j == needle.Length) return i;
        }
        return -1;
    }

    // copy of an animation file with extra bones added, held still at the given position
    static void AugmentOmf(string src, string dst, List<KeyValuePair<string, float[]>> extra)
    {
        byte[] b = File.ReadAllBytes(src);
        var top = StrictMasked(b);
        var pc = top[15];
        byte[] d = new byte[pc.Size];
        Buffer.BlockCopy(b, pc.Off, d, 0, pc.Size);
        int q = 0;
        ushort ver = BitConverter.ToUInt16(d, q);
        ushort np = BitConverter.ToUInt16(d, q + 2); q += 4;
        var parts = new List<KeyValuePair<string, List<KeyValuePair<string, uint>>>>();
        int nb = 0;
        for (int i = 0; i < np; i++)
        {
            string nm = ZStr(d, ref q);
            ushort n = BitConverter.ToUInt16(d, q); q += 2;
            var bl = new List<KeyValuePair<string, uint>>();
            for (int j = 0; j < n; j++)
            {
                string bn = ZStr(d, ref q);
                uint idx = BitConverter.ToUInt32(d, q); q += 4;
                bl.Add(new KeyValuePair<string, uint>(bn, idx)); nb++;
            }
            parts.Add(new KeyValuePair<string, List<KeyValuePair<string, uint>>>(nm, bl));
        }
        byte[] rest = new byte[d.Length - q];
        Buffer.BlockCopy(d, q, rest, 0, rest.Length);
        for (int k = 0; k < extra.Count; k++) parts[0].Value.Add(new KeyValuePair<string, uint>(extra[k].Key, (uint)(nb + k)));

        var ps = new MemoryStream();
        var pw = new BinaryWriter(ps);
        pw.Write(ver); pw.Write((ushort)parts.Count);
        foreach (var part in parts)
        {
            pw.Write(Encoding.ASCII.GetBytes(part.Key)); pw.Write((byte)0);
            pw.Write((ushort)part.Value.Count);
            foreach (var bi in part.Value) { pw.Write(Encoding.ASCII.GetBytes(bi.Key)); pw.Write((byte)0); pw.Write(bi.Value); }
        }
        pw.Write(rest); pw.Flush();

        var mc = top[14];
        var ms = new MemoryStream();
        foreach (var m in Chunks(b, mc.Off, mc.Off + mc.Size, true))
        {
            byte[] md = new byte[m.Size];
            Buffer.BlockCopy(b, m.Off, md, 0, m.Size);
            if (m.Id == 0) { var x = Pack(0, md); ms.Write(x, 0, x.Length); continue; }
            var add = new MemoryStream();
            var aw = new BinaryWriter(add);
            foreach (var e in extra)
            {
                for (int i = 0; i < 3; i++)
                    if (Math.Abs(e.Value[i]) >= 1e-6) throw new InvalidDataException("bone " + e.Key + " is rotated in the bind pose");
                aw.Write((byte)2);
                aw.Write((short)0); aw.Write((short)0); aw.Write((short)0); aw.Write((short)32767);
                aw.Write(e.Value[3]); aw.Write(e.Value[4]); aw.Write(e.Value[5]);
            }
            aw.Flush();
            var ab = add.ToArray();
            var both = new byte[md.Length + ab.Length];
            Buffer.BlockCopy(md, 0, both, 0, md.Length);
            Buffer.BlockCopy(ab, 0, both, md.Length, ab.Length);
            var y = Pack(m.Id, both);
            ms.Write(y, 0, y.Length);
        }
        var o1 = Pack(14, ms.ToArray());
        var o2 = Pack(15, ps.ToArray());
        Directory.CreateDirectory(Path.GetDirectoryName(dst));
        var all = new byte[o1.Length + o2.Length];
        Buffer.BlockCopy(o1, 0, all, 0, o1.Length);
        Buffer.BlockCopy(o2, 0, all, o1.Length, o2.Length);
        File.WriteAllBytes(dst, all);
    }

    static readonly Dictionary<uint, int[]> Fmt = new Dictionary<uint, int[]> {
        { 0x12071980u, new[] { 60, 0 } }, { 0x240e3300u, new[] { 64, 4 } },
        { 0x3u, new[] { 70, 6 } }, { 0x4u, new[] { 76, 8 } }, { 0x1u, new[] { 60, 0 } }, { 0x2u, new[] { 64, 4 } } };

    static void ScaleFloat(byte[] b, int p, double s)
    {
        float f = BitConverter.ToSingle(b, p);
        Buffer.BlockCopy(BitConverter.GetBytes((float)((double)f * s)), 0, b, p, 4);
    }
    static void ScaleHdr(byte[] b, int o, double s)
    {
        for (int k = 0; k < 6; k++) ScaleFloat(b, o + 4 + 4 * k, s);
        for (int k = 0; k < 4; k++) ScaleFloat(b, o + 28 + 4 * k, s);
    }

    // resize a model (header boxes + every vertex position)
    public static void ScaleOgf(string path, double s)
    {
        byte[] b = File.ReadAllBytes(path);
        var top = TopMasked(b, 0, b.Length);
        ScaleHdr(b, top[1].Off, s);
        var kids = top[9];
        foreach (var ch in Chunks(b, kids.Off, kids.Off + kids.Size, false))
        {
            var sub = TopMasked(b, ch.Off, ch.Off + ch.Size);
            ScaleHdr(b, sub[1].Off, s);
            var vc = sub[3];
            uint f = BitConverter.ToUInt32(b, vc.Off);
            int cnt = (int)BitConverter.ToUInt32(b, vc.Off + 4);
            int[] st;
            if (!Fmt.TryGetValue(f, out st)) throw new InvalidDataException("unknown vertex format 0x" + f.ToString("x"));
            if (8 + st[0] * cnt != vc.Size) throw new InvalidDataException("vertex block size mismatch");
            for (int k = 0; k < cnt; k++)
            {
                int p = vc.Off + 8 + k * st[0] + st[1];
                ScaleFloat(b, p, s); ScaleFloat(b, p + 4, s); ScaleFloat(b, p + 8, s);
            }
        }
        File.WriteAllBytes(path, b);
    }

    // modsDir = MO2 mods folder; outDir = where gamedata\meshes\anomaly_weapons\... is written.
    // Returns the relative paths written (forward slashes, under gamedata/meshes/anomaly_weapons/).
    public static List<string> Build(string modsDir, string outDir, List<string> log)
    {
        string M = Path.Combine(modsDir, @"MRAA 1.4.6\gamedata\meshes\anomaly_weapons");
        string HA = Path.Combine(M, "hud_animation");
        string[] roots = {
            Path.Combine(modsDir, @"3DSS MRAA\gamedata\meshes\anomaly_weapons"),
            Path.Combine(modsDir, @"MRAA 1.4 3DSS Meshes\gamedata\meshes\anomaly_weapons") };
        foreach (var r in roots) if (!Directory.Exists(r)) throw new DirectoryNotFoundException("missing " + r);
        if (!Directory.Exists(HA)) throw new DirectoryNotFoundException("missing " + HA);

        var final = new Dictionary<string, string>();
        foreach (var root in roots)
        {
            int bl = root.TrimEnd('\\').Length + 1;
            foreach (var f in Directory.GetFiles(root, "*.ogf", SearchOption.AllDirectories))
                final[f.Substring(bl).Replace('\\', '/')] = f;
        }
        string OUT = Path.Combine(outDir, @"gamedata\meshes\anomaly_weapons");
        var made = new Dictionary<string, string>();
        var written = new List<string>();
        var rels = new List<string>(final.Keys);
        rels.Sort(StringComparer.Ordinal);
        foreach (var rel in rels)
        {
            string p = final[rel];
            string reference; List<string> bones;
            Info(p, out reference, out bones);
            string mp = Path.Combine(M, rel.Replace('/', '\\'));
            string mref = null;
            List<string> mb;
            if (File.Exists(mp)) Info(mp, out mref, out mb);
            else if (rel.Contains("lr300")) Info(Path.Combine(M, @"wpn_lr300\wpn_lr300_hud.ogf"), out mref, out mb);
            if (mref == null || reference == mref) continue;

            string[] segs = mref.Split('\\');
            string bas = segs[segs.Length - 1];
            string omf = Path.Combine(HA, bas + ".omf");
            if (!File.Exists(omf)) throw new FileNotFoundException("animation file missing: " + omf);
            byte[] ob = File.ReadAllBytes(omf);
            var t = StrictMasked(ob);
            var c15 = t[15];
            var extra = new List<string>();
            foreach (var x in bones) if (IndexOf(ob, c15.Off, c15.Size, Encoding.ASCII.GetBytes(x)) < 0) extra.Add(x);
            string newref = mref;
            if (extra.Count > 0)
            {
                var bp = BindPose(p);
                var sortedExtra = new List<string>(extra);
                sortedExtra.Sort(StringComparer.Ordinal);
                string key = bas + "_vpcp3dss_" + string.Join("_", sortedExtra.ToArray());
                if (!made.ContainsKey(key))
                {
                    int n = 0;
                    foreach (var k in made.Keys) if (k.StartsWith(bas + "_vpcp3dss", StringComparison.Ordinal)) n++;
                    string nm = bas + "_vpcp3dss" + (n > 0 ? (n + 1).ToString() : "");
                    var ex = new List<KeyValuePair<string, float[]>>();
                    foreach (var x in extra) ex.Add(new KeyValuePair<string, float[]>(x, bp[x]));
                    AugmentOmf(omf, Path.Combine(OUT, @"hud_animation\" + nm + ".omf"), ex);
                    made[key] = nm;
                    written.Add("hud_animation/" + nm + ".omf");
                }
                newref = @"anomaly_weapons\hud_animation\" + made[key];
            }
            // write the model with the new animation reference
            byte[] b = File.ReadAllBytes(p);
            var outb = new MemoryStream();
            foreach (var ch in Chunks(b, 0, b.Length, true))
            {
                uint ii = ch.Id & 0x7fffffffu;
                byte[] rb = Encoding.ASCII.GetBytes(newref);
                byte[] blk;
                if (ii == 24)
                {
                    var data = new byte[4 + rb.Length + 1];
                    Buffer.BlockCopy(BitConverter.GetBytes(1u), 0, data, 0, 4);
                    Buffer.BlockCopy(rb, 0, data, 4, rb.Length);
                    blk = Pack(ch.Id, data);
                }
                else if (ii == 19)
                {
                    var data = new byte[rb.Length + 1];
                    Buffer.BlockCopy(rb, 0, data, 0, rb.Length);
                    blk = Pack(ch.Id, data);
                }
                else
                {
                    blk = new byte[ch.Size + 8];
                    Buffer.BlockCopy(b, ch.Off - 8, blk, 0, ch.Size + 8);
                }
                outb.Write(blk, 0, blk.Length);
            }
            string dst = Path.Combine(OUT, rel.Replace('/', '\\'));
            Directory.CreateDirectory(Path.GetDirectoryName(dst));
            File.WriteAllBytes(dst, outb.ToArray());
            written.Add(rel);
            log.Add(rel + " -> " + newref + (extra.Count > 0 ? "  (+" + string.Join(",", extra.ToArray()) + ")" : ""));
        }
        string p90 = Path.Combine(OUT, @"wpn_p90\wpn_p90_hud.ogf");
        if (!File.Exists(p90)) throw new FileNotFoundException("P90 model was not produced");
        ScaleOgf(p90, 0.9);
        log.Add("wpn_p90/wpn_p90_hud.ogf resized to 0.9");
        var result = new List<string>();
        foreach (var x in written) result.Add("gamedata/meshes/anomaly_weapons/" + x);
        return result;
    }
}

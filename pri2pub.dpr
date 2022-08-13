library pri2pub;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters.

  Important note about VCL usage: when this DLL will be implicitly
  loaded and this DLL uses TWicImage / TImageCollection created in
  any unit initialization section, then Vcl.WicImageInit must be
  included into your library's USES clause. }

uses
  System.SysUtils,
  System.Classes, web3, web3.crypto, web3.eth.types, web3.utils, Winapi.Windows,
  web3.eth.abi, web3.eth.tx, web3.eth.utils, System.DateUtils, System.Variants,
  Velthuis.BigIntegers, web3.eth;

{$R *.res}
const
  DllVer=1.0015;

procedure Address(pri: Pansichar; pub: Pansichar); stdcall;
var
  pubKey: TBytes;
  buffer: TBytes;
  prik: TprivateKey;
  pubk: TAddress;
begin
  try
    prik := pri;
    pubKey := web3.crypto.publicKeyFromPrivateKey(prik.Parameters);
    buffer := web3.utils.sha3(pubKey);
    Delete(buffer, 0, 12);
    pubk := TAddress.New(web3.utils.toHex(buffer));
    CopyMemory(pub, @pubk[1], length(pubk));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(pub, @errinfo[1], length(errinfo));
  end;
end;

procedure eth_sign(pri: Pansichar; data: Pansichar; res: Pansichar); stdcall;
begin
  try
    var
    signdata := Ansistring(web3.eth.sign(pri, data));
    CopyMemory(res, @signdata[1], length(signdata))
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;

end;

procedure AbiEncode(func: Pansichar; res: Pansichar; param: Pansichar); stdcall;
var
  strParam: string;
  Params: array of TvarRec;
begin
  try
    strParam := param;
    var
    ParamArr := strParam.Split([',']);
    setlength(Params, length(ParamArr));
    for var i := 0 to length(ParamArr) - 1 do
    begin
      Params[i].VType := vtUnicodeString;
      Params[i].VUnicodeString := pchar(ParamArr[i]);
    end;
    var
    ret := Ansistring(web3.eth.abi.encode(func, Params));
    CopyMemory(res, @ret[1], length(ret));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;

end;

procedure AbiEncodeEx(func: Pansichar; res: Pansichar;
  param: Pansichar); stdcall;
var
  strParam: string;
  Params: array of TvarRec;
begin
  try
    strParam := param;
    var
    ParamArr := strParam.Split([',']);
    setlength(Params, length(ParamArr));
    for var i := 0 to length(ParamArr) - 1 do
    begin
      if ParamArr[i].Contains('|') then
      begin
        var
        tparr := ParamArr[i].Split(['|']);
        var
        tp := TContractArray.Create;
        for var arg in tparr do
          tp.Add(arg);
        Params[i].VType := vtobject;
        Params[i].VObject := tp;
      end
      else
      begin
        Params[i].VType := vtUnicodeString;
        Params[i].VUnicodeString := pchar(ParamArr[i]);
      end;
    end;
    var
    ret := Ansistring(web3.eth.abi.encode(func, Params));
    CopyMemory(res, @ret[1], length(ret));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;

end;

procedure sign(chainId: Integer; nonce: Integer; From: Pansichar;
  ToAdd: Pansichar; Value: Pansichar; GasLimit: Integer;
  res: Pansichar); stdcall;
begin
  try

    var
    sig := signTransactionLegacy(chainId, nonce, From, ToAdd,
      web3.eth.utils.toWei(Value, TEthUnit.ether), '', 5000000000, GasLimit);
    var
    ret := Ansistring(sig);
    CopyMemory(res, @ret[1], length(ret));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;

end;

procedure SignEx(chainId: Integer; nonce: Integer; From: Pansichar;
  ToAdd: Pansichar; Value: Pansichar; GasLimit: Integer; data: Pansichar;
  res: Pansichar); stdcall;
begin
  try

    var
    sig := signTransactionLegacy(chainId, nonce, From, ToAdd,
      web3.eth.utils.toWei(Value, TEthUnit.ether), data, 5000000000, GasLimit);

    var
    ret := Ansistring(sig);
    CopyMemory(res, @ret[1], length(ret));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;

end;

procedure SignEx2(chainId: Integer; nonce: Integer; From: Pansichar;
  ToAdd: Pansichar; Value: Pansichar; GasPrice: Pansichar; GasLimit: Integer;
  data: Pansichar; res: Pansichar); stdcall;
begin
  try


    var
    sig := signTransactionLegacy(chainId, nonce, From, ToAdd,
      web3.eth.utils.toWei(Value, TEthUnit.ether), data, BigInteger(GasPrice),
      GasLimit);


    var
    ret := Ansistring(sig);
    CopyMemory(res, @ret[1], length(ret));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;

end;

procedure SignEx3(chainId: Integer; nonce: Integer; From: Pansichar;
  ToAdd: Pansichar; Value: Pansichar; maxPriorityFee: Pansichar;
  maxFee: Pansichar; GasLimit: Integer; data: Pansichar;
  res: Pansichar); stdcall;
begin
  try

    // maxPriorityFee: TWei; maxFee
    var
    sig := signTransactionType2(chainId, nonce, From, ToAdd,
      web3.eth.utils.toWei(Value, TEthUnit.ether), data, maxPriorityFee, maxFee,
      GasLimit);


    var
    ret := Ansistring(sig);
    CopyMemory(res, @ret[1], length(ret));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;

end;

procedure toWei(data: Pansichar; res: Pansichar); stdcall;
begin
  try
    var
    sig := web3.eth.utils.toWei(data, TEthUnit.ether);
    var
    ret := Ansistring(sig);
    CopyMemory(res, @ret[1], length(ret));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;
end;

const
  单位表: array[0..23] of string = (
    '0',
    '10',
    '100',
    '1000',
    '10000',
    '100000',
    '1000000',
    '10000000',
    '100000000',
    '1000000000',
    '10000000000',
    '100000000000',
    '1000000000000',
    '10000000000000',
    '100000000000000',
    '1000000000000000',
    '10000000000000000',
    '100000000000000000',
    '1000000000000000000',
    '10000000000000000000',
    '100000000000000000000',
    '1000000000000000000000',
    '10000000000000000000000',
    '100000000000000000000000');
function 精度转换(input: string; &unit: Integer): TWei;
begin
  const base = 单位表[&unit];
  const baseLen = 单位表[&unit].Length;
  // is it negative?
  const negative = (input.Length > 0) and (input[System.Low(input)] = '-');
  if negative then
    Delete(input, System.Low(input), 1);
  if (input = '') or (input = '.') then
    raise EWeb3.CreateFmt('Error while converting %s to wei. Invalid value.', [input]);
  // split it into a whole and fractional part
  const comps = input.Split(['.']);
  if Length(comps) > 2 then
    raise EWeb3.CreateFmt('Error while converting %s to wei. Too many decimal points.', [input]);
  var whole: string := comps[0];
  var fract: string;
  if Length(comps) > 1 then
    fract := comps[1];
  Result := BigInteger.Multiply(whole, base);
  if fract.Length > 0 then
  begin
    while fract.Length < baseLen - 1 do
      fract := fract + '0';
    Result := BigInteger.Add(Result, fract);
  end;
  if negative then
    Result := BigInteger.Negate(Result);
end;
{   //单位转换
procedure toWeiEx(data: Pansichar; De: Integer; res: Pansichar); stdcall;
begin
  try
    var
    sig := web3.eth.utils.toWei(data, TEthUnit(De));
    var
    ret := Ansistring(sig);
    CopyMemory(res, @ret[1], length(ret));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;
end;
}

procedure toWeiEx(data: Pansichar; De: Integer; res: Pansichar); stdcall;
begin
  try
    var
    sig := 精度转换(data, de);
    var
    ret := Ansistring(sig);
    CopyMemory(res, @ret[1], length(ret));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;
end;


procedure toWeiHex(data: Pansichar; De: Integer; res: Pansichar); stdcall;
begin
  try
    var
    sig :=  精度转换(data, de);
    var
    ret := Ansistring(web3.utils.toHex(sig));

    CopyMemory(res, @ret[1], length(ret));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;
end;

procedure GenAddr(res: Pansichar; num: Integer = 1); stdcall;
begin
  try
    var str: Ansistring;

    for var i := 1 to num do
    begin
      var
      pri := TprivateKey.Generate;
      var
      pubKey := web3.crypto.publicKeyFromPrivateKey(pri.Parameters);
      var
      buffer := web3.utils.sha3(pubKey);
      Delete(buffer, 0, 12);
      var
      addr := TAddress.New(web3.utils.toHex(buffer));

      str := str + addr + '----' + pri + sLineBreak;
    end;

    CopyMemory(res, @str[1], length(str));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;

end;

procedure sha3(sources: pByte; len: Integer; res: pByte; var reslen: Integer); stdcall;
begin
  try
    var
    sb := Bytesof(sources, len);
    var
    sha3res := web3.utils.sha3(sb);
    CopyMemory(res, @sha3res[0], length(sha3res));
    reslen := length(sha3res)
  except
    on E: Exception do
      reslen := 0;
  end;
end;

procedure Eip55Wallet(wallet: Pansichar; res: Pansichar);stdcall;
var
  mywallet: string;
  resdata: Ansistring;
begin
  try
    resdata := '0x';
    mywallet := strpas(wallet);
    mywallet := mywallet.ToLower.Replace('0x', '');
    var sha3res := web3.utils.sha3(Tencoding.Default.GetBytes(mywallet));
    var sha3Hex := web3.utils.toHex(sha3res).Replace('0x', '');
    for var i := 1 to mywallet.length do
    begin
      if StrtoInt('$' + sha3Hex[i]) > 7 then
      begin
        resdata := resdata + String(mywallet[i]).ToUpper;
      end
      else
      begin
        resdata := resdata + mywallet[i];
      end;
    end;
    CopyMemory(res, @resdata[1], length(resdata));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;

end;

procedure FromWeiHex(Value: Pansichar; jingdu: Integer;
  res: Pansichar); stdcall;
begin
  try
    var str: Ansistring;
    str := web3.eth.utils.fromWei(Twei.Create(Value), TEthUnit(jingdu));
    CopyMemory(res, @str[1], length(str));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;
end;

procedure toBin(Value: Pansichar; res: Pansichar); stdcall;
begin
  try
    var str: Ansistring;
    str := '0b' + Twei.Create(Value).ToBinaryString;
    CopyMemory(res, @str[1], length(str));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;
end;

procedure toHex(Value: Pansichar; res: Pansichar); stdcall;
begin
  try
    var str: Ansistring;
    str :=Ansistring( BigInteger(Value).ToHexString);
    CopyMemory(res, @str[1], length(str));
  except
    var errinfo: Ansistring := 'err';
    CopyMemory(res, @errinfo[1], length(errinfo));
  end;
end;

function Ver:Single;stdcall;
begin
  Result:=DllVer;
end;
exports
  Address, eth_sign, AbiEncode, sign, SignEx, toWei, toWeiEx, GenAddr, toWeiHex,
  AbiEncodeEx, FromWeiHex, toBin, SignEx2, SignEx3, sha3,Eip55Wallet,Ver,toHex;

begin
  IsMultiThread := True;
end.

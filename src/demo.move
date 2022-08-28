module Demo::nft_mint {
    use std::signer;
	use std::vector;
	use std::string;
	
    use std::string::String;

    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_token::token::create_collection;
	use aptos_token::token::create_token_script;
    use aptos_token::token_coin_swap::list_token_for_swap;
	use aptos_token::token_coin_swap::exchange_coin_for_token;
	
    const ENOT_ENOUGH_COIN: u64 = 7;
    const ENO_MINT_CAPABILITY: u64 = 11;
	const CREATOR: address = @0x8df1c45ae32be3f55aaa857a1410203dfade3ac4aa2e4fefeec060f87170e241;
    const TOTAL_NFT: u64 = 10000;
    const NFT_PRICE: u64 = 1000;
	
	/// Resource that wraps an integer counter
    struct MintCounter has key { i: u64 }
    struct SaleCounter has key { i: u64 }
	
	 fun init_module(account: &signer){
        create_nft_collection(account);
    }
	
	/// Publish a `MintCounter` resource with value `i` under the given `account`
    fun publish_mint(account: &signer, i: u64) {
	  assert!(CREATOR == signer::address_of(account), ENO_MINT_CAPABILITY);
      move_to(account, MintCounter { i })
    }
	
	/// Read the value in the `MintCounter` resource stored at `addr`
    public fun get_count_mint(addr: address): u64 acquires MintCounter {
        borrow_global<MintCounter>(addr).i
    }
	
	/// Increment the value of `addr`'s `MintCounter` resource
    fun increment_mint(addr: address) acquires MintCounter {
        let c_ref = &mut borrow_global_mut<MintCounter>(addr).i;
        *c_ref = *c_ref + 1
    }

    /// Publish a `SaleCounter` resource with value `i` under the given `account`
    fun publish_sale(account: &signer, i: u64) {
	  assert!(CREATOR == signer::address_of(account), ENO_MINT_CAPABILITY);
      move_to(account, SaleCounter { i })
    }
	
	/// Read the value in the `SaleCounter` resource stored at `addr`
    public fun get_count_sale(addr: address): u64 acquires SaleCounter {
        borrow_global<SaleCounter>(addr).i
    }
	
	/// Increment the value of `addr`'s `SaleCounter` resource
    fun increment_sale(addr: address) acquires SaleCounter {
        let c_ref = &mut borrow_global_mut<SaleCounter>(addr).i;
        *c_ref = *c_ref + 1
    }
	
	public fun get_token_name(): String {
        
        string::utf8(b"TEST #")
    }
	
	public fun get_collection_name(): String {
        string::utf8(b"Aptos NFT Demo")
    }

    public fun get_collection_desc(): String {
        string::utf8(b"Demo Collection")
    }

    public fun get_collection_uri(): String {
        string::utf8(b"https://i.postimg.cc/BvVZYVkL/pexels-bryan-dijkhuizen-12194524.jpg")
    }

    public fun get_uri(count: u64): String{
		let _token_uri = string::utf8(b"https://ipfs.io/ipfs/QmUS4whFKh4uP3CGQNtzN9KF9kA2Xe7paCx6fabxwt1Afu/");
		let _serial = get_serial_num(count);
		string::append(&mut _token_uri, _serial);
        string::append(&mut _token_uri, string::utf8(b".png"));
		
		_token_uri
    }
	
	
	public entry fun create_nft_collection(
        account: &signer
    ) {
        let mutate_setting = vector<bool>[true, true, true];
		assert!(CREATOR == signer::address_of(account), ENO_MINT_CAPABILITY);
        create_collection(
            account,
            get_collection_name(),
            get_collection_desc(),
            get_collection_uri(),
            TOTAL_NFT,
            mutate_setting
        );
		
		publish_mint(account, 1);
		publish_sale(account, 1);
    }
	
	fun get_serial_num(num: u64): String{
		
		let v1 = vector::empty();
		
		while (num/10 > 0){
			let rem = num%10;
			vector::push_back(&mut v1, (rem+48 as u8));
			num = num/10;
		};
		
		vector::push_back(&mut v1, (num+48 as u8));
		
		vector::reverse(&mut v1);
		
		string::utf8(v1)
	}
	
	public entry fun mint_nft(
        account: &signer,
        num_nft: u64
    ) acquires MintCounter {

        let default_keys = vector<String>[];
        let default_vals = vector<vector<u8>>[];
        let default_types = vector<String>[];
        let mutate_setting = vector<bool>[false, true, false, false, true];
		let i = 0;
		
		let _token_name = get_token_name();
		
		let _count = 0;
		let _serial = string::utf8(b"");
		
		while ( i < num_nft){
			i = i + 1;
			_count = get_count_mint(CREATOR);
			_serial = get_serial_num(_count);
			string::append(&mut _token_name, _serial);
			create_token_script(
				account,
				get_collection_name(),
				_token_name,
				get_collection_desc(),
				1,
				1,
				get_uri(_count),
				CREATOR,
				10000, //royalty denominator
				500,  // royalty numerator -- 500 = 5% 
				mutate_setting,
				default_keys,
				default_vals,
				default_types,
			);

            nft_list(account, _token_name);
			
			_token_name = get_token_name();
			
			increment_mint(CREATOR);
		}
    }

    public fun nft_list(
        token_owner: &signer,
        token_name: String
    ){
        list_token_for_swap<AptosCoin>(token_owner, CREATOR, get_collection_name(), token_name, 0, 1, NFT_PRICE, 0)

    }

    public fun buy_nft(
        coin_owner: &signer,
        coin_amount: u64,
        num_nft: u64
    ) acquires SaleCounter {
        assert!(coin_amount == NFT_PRICE*num_nft, ENOT_ENOUGH_COIN);
        
        let i = 0;

        let _count = 0;
		let _serial = string::utf8(b"");
        let _token_name = get_token_name();

        while ( i < num_nft){
			i = i + 1;

            _count = get_count_sale(CREATOR);
            _serial = get_serial_num(_count);
			string::append(&mut _token_name, _serial);
            exchange_coin_for_token<AptosCoin>(coin_owner, NFT_PRICE, CREATOR, CREATOR, get_collection_name(), _token_name, 0, 1);
            
			_token_name = get_token_name();
			
            increment_sale(CREATOR);
        }
    }
}
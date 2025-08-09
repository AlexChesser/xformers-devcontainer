import torch
import xformers.ops as xops

def main():
    # Device
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    
    # Sample input: batch_size=2, seq_len=4, embed_dim=8
    batch_size, seq_len, embed_dim = 2, 4, 8
    query = torch.randn(batch_size, seq_len, embed_dim, device=device)
    key = torch.randn(batch_size, seq_len, embed_dim, device=device)
    value = torch.randn(batch_size, seq_len, embed_dim, device=device)
    
    # Use a concrete implementation from xformers.ops
    # The function call handles creating the attention mechanism internally
    output = xops.memory_efficient_attention(query, key, value)
    
    print("Output shape:", output.shape)
    print("Output tensor:", output)

if __name__ == "__main__":
    main()